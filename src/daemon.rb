#!/usr/bin/ruby

require_relative 'core'
#
# RaspberyPi上で動作するデーモンオブジェクト
# @author FAE

class SensingControlDaemon
    # デーモンの初期化を行うメソッド
    def initialize
    @term_flag         = false    # デーモン停止用フラグ
    @loop_count        = 0        # デーモンのメインループ回数
    @atomic_interval   = 1        # デーモン動作周期周期 (秒)
    @db_store_interval = 2        # DBデータ格納周期
    @db_load_interval  = 2        # DBデータ取得周期

    @cloudserver = 'rubyiot.rcloud.jp'
    @cloudport   = 80
    @localserver = 'localhost'
    @localport   = 3131

    @sensor  = Sensor.new         # センサオブジェクト生成

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
    @gateway_id = 1
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

    @localdb = LocalDb.new(@localserver,@localport)        # ローカルDBオブジェクト生成
    @clouddb = CloudDb.new(@cloudserver,@cloudport)        # クラウドDBオブジェクト生成

begin
   response = @localdb.getSensor(@gateway_id)
   puts "ローカルからの応答 #{response}"
rescue
   puts "ローカル準備中"
   sleep 3
   retry
end

begin
   response = @clouddb.getSensor(@gateway_id)
   puts "クラウドからの応答 #{response}"
rescue
   puts "クラウド準備中"
   sleep 3
   retry
end

    @settime = Time.now
    @settime = @settime + @interval

    loop do
      # 終了フラグが立っていたらメインループを抜けて終了
      break if @term_flag == true

      puts "loop = #{@loop_count}"

loop do
         puts "start"

         # センサから情報を取得
         @sensor.recvdata

         @dev_status = @sensor.get_device_status.to_i
         @temperature = @sensor.sense.to_f
         @fan_status = @sensor.get_fan_status.to_i
         @fail_status  = @sensor.get_fail_status.to_i

         if @dev_status != 3 then
           puts "dev status error : {#@dev_status}"
           next
         end
         break
end

      puts "------ INPUT DATA -------"
      puts "temp = #{@temperature}"
      puts "dev  = #{@dev_status}"
      puts "fan  = #{@fan_status}"
      puts "fail = #{@fail_status}"
      puts @fail_status.class
      puts "-------------------------"

      # DB格納処理
      if Time.now > @settime then

        @settime = Time.now + @interval

	# センシングデータ格納処理
        timestamp = Time.now.strftime("%Y/%m/%d %H:%M:%S")
begin
        @localdb.storeSensingData(@local_sensor_id, timestamp, @temperature)
        @clouddb.storeSensingData(@sensor_id, timestamp, @temperature)
rescue
	puts "db store data error"
end

        # 温度状態が異常の場合、cloudにalertを通知する
        if @fail_status == 1 then
          #puts "##### 高温異常状態検出 #####"
begin
          response = @clouddb.setSensorAlert(@sensor_id,@temperature,@limit_min,@limit_max)
rescue
	  puts "clouddb setSensorAlert Error"
end
          #puts "##### 応答: #{response.body}"
        end
        if @fail_status == 2 then
          #puts "##### 低温異常状態検出 #####"
begin
          response = @clouddb.setSensorAlert(@sensor_id,@temperature,@limit_min,@limit_max)
rescue
	  puts "clouddb setSensorAlert Error"
end
          #puts "##### 応答: #{response.body}"
        end

      end 

      # DB取得処理
catch :b_loop do
        if 0 == (@loop_count % @db_load_interval) then
	# センシングパラメータ取得処理
begin
	response_hash = @clouddb.getMonitorRange(@sensor_id)
rescue
        puts "get motion range error"
        throw :b_loop
end
	@limit_min = response_hash["min"]
	@limit_max = response_hash["max"]
        puts "threshold min=#{@limit_min} max=#{@limit_max}"

        #今回gateway_id は1固定
begin
	response_hash = @clouddb.getOperation(1)
rescue
	puts "get operation error"
        throw :b_loop
end
        puts "control info = #{response_hash}"
        puts response_hash.size

        if response_hash.size == 0 then
          puts "response_hash null"
          #@value = @fan_status
        else
	  xxx = response_hash.values
	  
          @operation_id = xxx[0]["operation_id"]
          @value = xxx[0]["value"]
           
          puts "operation_id = #{@operation_id} / value = #{@value}"

begin
	response_hash = @clouddb.setOperationStatus(@operation_id,0)
rescue
        throw :b_loop
end
        end
      end
end # :b_loop do

  # ローカルDBの操作指示は未サポートとする

      # デバッグ用でテーブル内情報を表示
#     @localdb.loadSensingData

      puts "------ OUTPUT DATA ------"
      puts "limit max = {#@limit_max}"
      puts "limit min = {#@limit_min}"
      puts "value     = {#@value}"
      puts "-------------------------"

begin
      @sensor.senddata(@limit_max.to_f,@limit_min.to_f,@value)
rescue
     puts "senddata skip"
end


      # ループ周期
      sleep @atomic_interval
      @loop_count += 1
    end
  end
end


daemon_app = SensingControlDaemon.new
daemon_app.exec

