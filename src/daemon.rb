#!/usr/bin/ruby -Ku

# @author FAE
# 2015/10/29

require_relative 'core'

class DataProcessHandler
	def initialize

		@gateway_id = 1
#		@gateway_id = 2

		@localdb_host = "localhost"
		@localdb_port = 3131
		@cloud_host = 'http://rubyiot.rcloud.jp'
		@cloud_port   = 80

		#create LocalDb and cloudDb class object
		@localdb = LocalDb.new(@localdb_host,@localdb_port)
		@clouddb = CloudDb.new(@cloud_host,@cloud_port)

		begin
			response = @localdb.getSensor(@gateway_id)
			puts "ローカルからの応答 #{response}"
		rescue
			puts "ローカル準備中"
			sleep 3
			retry
		end

		@clouddb.login

		begin
			response = @clouddb.getSensor(@gateway_id)
			puts "クラウドからの応答 #{response}"
		rescue
			puts "クラウド準備中"
			sleep 3
			retry
		end
		@uid_hash = Hash.new
###################################debug
#res3 = @clouddb.setOperation(42, 0)
#puts "setOperation=#{res3.body}"
###################################

	end

	def store_data(id,time,data)
		p __method__
		begin
			#resLocal = @localdb.storeSensingData(id,time,data)
			resCloud = @clouddb.storeSensingData(id,time,data)
		rescue
			puts "db store data error"
		end
		
		p resCloud
	end

	def notify_alert(id,temp,min,max)
		p __method__
		begin
			res = @clouddb.setSensorAlert(id,temp,min,max)
		rescue
			puts "clouddb setSensorAlert Error"
		end
		#puts "##### 応答: #{res.body}"
	end 

	def process_data(id)
		p __method__
		res = @clouddb.getMonitorRange(id)
		limit_min = res["min"]
		limit_max = res["max"]
		res2 = @clouddb.getOperation(@gateway_id)
		puts "RES"
		puts res
		puts "RES2"
		puts res2
		@clouddb.setOperationStatus(res2[0]["operation_id"],0)
		data = {
			"min" => limit_min,
			"max" => limit_max,
			"value" => res2.values[0]["operation_id"],	
			"addr" => id
		}
		puts "data"
		puts data
		return data
	end

	def has_sensor_id(id)
		p __method__
		if !(@uid_hash.has_key?(id)) then
			res = @clouddb.postDevice(@gateway_id,id)
			@uid_hash.store(id,res.values[0][0]["id"])
			res2 = @clouddb.setMonitorRange(@uid_hash[id], 10, 30) #debug
			puts res.values[0][0]["id"]
			puts res.values[0][1]["id"]
		end
		return @uid_hash[id]
	end

end #class DataProcessHandler


class SensorMonitor
	def initialize
		#create Sensor class object
		@sensor = Sensor.new
		@recv_queue = Queue.new
	end

	def recv_data
		loop do
			@sensor.recvdata
			p @sensor.get_temp.to_f
			dev_status = @sensor.get_device_status.to_i
			if dev_status != 3 then
				puts "dev status error : #{dev_status}"
				next
			end
			break
		end
		data = {
			"dev_status" => @sensor.get_device_status.to_i,
			"temperature" => @sensor.get_temp.to_f,
			"fan_status" => @sensor.get_fan_status.to_i,
			"fail_status" => @sensor.get_fail_status.to_i,
			"addr" => @sensor.get_addr.to_s,
		}
		p data	
		@recv_queue.push(data)
	end

	def get_queue
		q = Queue.new
		l = @recv_queue.length
		l.times do
			q.push(@recv_queue.pop)
		end
		return q
	end

	def send_data(max,min,value)
		@sensor.senddata(max,min,value)
	end

end #class SensorMonitor


# RaspberyPi上で動作するデーモンオブジェクト
class SensingControlDaemon
    # デーモンの初期化を行うメソッド
    def initialize
    @term_flag         = false    # デーモン停止用フラグ
    @loop_count        = 0        # デーモンのメインループ回数
    @atomic_interval   = 1        # デーモン動作周期周期 (秒)
    @db_store_interval = 2        # DBデータ格納周期
    @db_load_interval  = 2        # DBデータ取得周期


    @sensor  = SensorMonitor.new         # センサオブジェクト生成
		@send_queue = Queue.new
		@recv_queue = Queue.new
		@data_process_handler = DataProcessHandler.new

    @limit_min = -20
    @limit_max = 45

    @status_temp = 0

    @value = 0
    @operation_id = 0

    @settime = Time.new
    @interval = 3

    @setopeflag = 0
    #@sensor_id = 9 
    @sensor_id = 1 
    @local_sensor_id = 15
  end

  # デーモン処理を実行するメソッド
  def exec
    puts "Start daemon."
#   daemonize     # プロセスデーモン化
    set_handler   # シグナルハンドラの設定
    main          # メインループ
    puts "Term daemon."
  end

  private
  # シグナルハンドラ設定を行うメソッド
  def set_handler
#    Signal.trap(:INT)  { @term_flag = true }
#    Signal.trap(:TERM) { @term_flag = true }
  end

  # プロセスをデーモン化するメソッド
  def daemonize
    Process.daemon(true, true)
  end


  # デーモンのメイン処理を実行するメソッド
  def main

	@settime = Time.now
	@settime = @settime + @interval

	sensor_t = Thread.new do
		while(1) do
			@sensor.recv_data
			#sleep 0.1 #DEBUG
		end
	end

	loop do
		# 終了フラグが立っていたらメインループを抜けて終了
		break if @term_flag == true
		puts "loop = #{@loop_count}"
		@recv_queue = @sensor.get_queue
		
		l = @recv_queue.length
		puts l, "recv_queue length"
		l.times do #TIMES1
			#data = @recv_queue.pop
			# DB格納処理
			if Time.now > @settime then
				begin 
					@settime = Time.now + @interval
					# センシングデータ格納処理
					timestamp = Time.now.strftime("%Y/%m/%d %H:%M:%S")
					dph_store_t = Thread.new do
						data = @recv_queue.pop
						sensor_id = @data_process_handler.has_sensor_id(data["addr"])
						@data_process_handler.store_data(sensor_id,timestamp,data["temperature"])
						p "#{data["fail_status"]} ###"
						if (data["fail_status"] != 3 ) then
							@data_process_handler.notify_alert(sensor_id,data["temperature"],@limit_min,@limit_max)
						end
					end
				rescue
					p "ERROR:"
				end
			end

			if 0 == (@loop_count % @db_load_interval) then
				# センシングパラメータ取得処理
				begin
					dph_get_t = Thread.new do
						p "dph_get_t"
						@send_queue.push(@data_process_handler.process_data(@data_process_handler.has_sensor_id(data["addr"])))
					end
				rescue
					puts "get motion range error"
				end
			end
			if @recv_queue.length == 0 then break end
		end #TIMES1

		sensor_send_t = Thread.new do
			len = @send_queue.length
			len.times do
				send_data = @send_queue.pop
				begin
					#value = data["value"] #DEBUG
					#value = 1 #DEBUG
					@sensor.senddata(send_data["min"].to_f,send_data["max"].to_f,send_data["value"],send_data["addr"])
				rescue
					puts "senddata skip"
				end
			end
		end
		# ループ周期
		sleep @atomic_interval
		@loop_count += 1
	end #main loop

	@clouddb.logout
  end #exec
end #class SensingControlDaemon

daemon_app = SensingControlDaemon.new
daemon_app.exec

