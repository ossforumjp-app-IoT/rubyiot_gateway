#!/usr/bin/ruby

require_relative 'core'

# RaspberyPi上で動作するデーモンオブジェクト
# @author FAE
# 2015/10/29

class DataProcessHandler
	def initialize(id)
		@uid_list = Array.new

		@localdb_host = "localhost"
		@localdb_port = 3131
		@cloud_host = 'http://rubyiot.rcloud.jp'
		@cloud_port   = 80

		#create LocalDb and cloudDb class object
		@localdb = LocalDb.new(@localdb_host,@localdb_port)
		@clouddb = CloudDb.new(@cloud_host,@cloud_port)

		begin
			response = @localdb.getSensor(id)
			puts "ローカルからの応答 #{response}"
		rescue
			puts "ローカル準備中"
			sleep 3
			retry
		end

		@clouddb.login

		begin
			response = @clouddb.getSensor(id)
			puts "クラウドからの応答 #{response}"
		rescue
			puts "クラウド準備中"
			sleep 3
			retry
		end
	end

	def store_data(id,time,temp)
		if !(@uid_list.include?(id)) then
			@clouddb.postDevice(id)
			@uid_list.push(id)
		end
		
		begin
			res=@localdb.storeSensingData(id,time,temp)
			ress=@clouddb.storeSensingData(id,time,temp)
		rescue
			puts "db store data error"
		end
	end

	def notify_alert(id,temp,min,max)
		begin
			res = @clouddb.setSensorAlert(id,temp,min,max)
		rescue
			puts "clouddb setSensorAlert Error"
		end
		#puts "##### 応答: #{res.body}"
	end 

	def process_data(id)
		res = @clouddb.getMonitorRange(id)
		limit_min = res["min"]
		limit_max = res["max"]
		res2 = @clouddb.getOperation(id)
		@clouddb.setOperationStatus(res2[0]["operation_id"],0)
		data = {
			"min" => limit_min,
			"max" => limit_max,
			"value" => res2.values[0]["operation_id"]	
		}
		return data
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
			@sensor.recvdata()
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
			#"addr" => @sensor.get_addr.to_s,
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
		@clouddb.senddata(max,min,value)
	end

end #class SensorMonitor


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
    @gateway_id = 1
		@data_process_handler = DataProcessHandler.new(@gateway_id)

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
			sleep 0.1 #DEBUG
		end
	end

	loop do
		# 終了フラグが立っていたらメインループを抜けて終了
		break if @term_flag == true
		puts "loop = #{@loop_count}"
		@recv_queue = @sensor.get_queue
		
		l = @recv_queue.length
			p "#{l} times@@@@@@@@@@@@@@@@@@@@@@@"
		l.times do #TIMES1
			data = @recv_queue.pop
			# DB格納処理
			if Time.now > @settime then
				begin 
					@settime = Time.now + @interval
					# センシングデータ格納処理
					timestamp = Time.now.strftime("%Y/%m/%d %H:%M:%S")
					dph_store_t = Thread.new do
						@data_process_handler.store_data(@gateway_id,timestamp,data["temperature"])
						if (data["fail_status"] == 1 || data["fail_status"] == 2 ) then
							@data_process_handler.notify_alert(@gateway_id,data["temperature"],@limit_min,@limit_max)
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
						#@send_queue.push(@data_process_handler.process_data(data["addr"]))
						@send_queue.push(@data_process_handler.process_data(1))
					end
				rescue
					puts "get motion range error"
				end
			end
			if @recv_queue.length == 0 then break end
		end #TIMES1

		sensor_send_t = Thread.new do
			l = @send_queue.length
			l.times do
				data = @send_queue.pop
				begin
					@limit_min = data["min"]
					@limit_max = data["max"]
					value = data["value"]
					value = 1 #DEBUG
					@sensor.send_data(@limit_max.to_f,@limit_min.to_f,value)
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

