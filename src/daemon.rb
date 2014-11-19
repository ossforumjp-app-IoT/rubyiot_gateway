#!/usr/bin/ruby

require_relative 'core'

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

    server = 'rubyiot.rcloud.jp'
    port   = 80

    @sensor  = Sensor.new         # センサオブジェクト生成
    @ac      = Airconditioner.new # エアコン制御オブジェクト生成
    @localdb = LocalDb.new        # ローカルDBオブジェクト生成
    @clouddb = CloudDb.new(server,port)        # クラウドDBオブジェクト生成

    @limit_min = -20
    @limit_max = 45

    @status_temp = 0

    @value = 0
    @operation_id = 0

    @setopeflag = 0
    @sensor_id = 9 
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
    loop do
      # 終了フラグが立っていたらメインループを抜けて終了
      break if @term_flag == true

      puts "loop = #{@loop_count}"

      # 温度取得処理
loop do
      @sensor.recvdata
      #temperature = @sensor.sense.to_i
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
      if 0 == (@loop_count % @db_store_interval) then

# device の登録部分はパスする
# ここは後回し
#        gateway_id = 1
#	status = 0
#	response = @clouddb.setDevice("0013a2004066107e",0x00,0x11,0x00)
#	puts "  クラウドからの応答：#{response.body}"


	# センシングデータ格納処理
        timestamp = Time.now.strftime("%Y/%m/%d %H:%M:%S")
#       @localdb.storeSensingData(0, timestamp, temperature)
        @clouddb.storeSensingData(@sensor_id, timestamp, @temperature)

        if @setopeflag == 1 then
          if @fan_status == @value.to_i then
            puts "##### Sensor 設定成功 #####"
	    response_hash = @clouddb.setOperationStatus(@operation_id,2)
            @setopeflag = 0
          else
            puts "##### Sensor 設定失敗 #####"
	    response_hash = @clouddb.setOperationStatus(@operation_id,1)
          end
        end

        if @fail_status == 1 then
          puts "##### 高温異常状態検出 #####"
          response = @clouddb.setSensorAlert(@sensor_id,@temperature,@limit_min,@limit_max)
          puts "##### 応答: #{response.body}"
        end
        if @fail_status == 2 then
          puts "##### 低温異常状態検出 #####"
          response = @clouddb.setSensorAlert(@sensor_id,@temperature,@limit_min,@limit_max)
          puts "##### 応答: #{response.body}"
        end

      end

      # DB取得処理
      if 0 == (@loop_count % @db_load_interval) then
	# センシングパラメータ取得処理
	response_hash = @clouddb.getMonitorRange(@sensor_id)
	@limit_min = response_hash["min"]
	@limit_max = response_hash["max"]
        puts "threshold min=#{@limit_min} max=#{@limit_max}"

        #今回gateway_id は1固定
	response_hash = @clouddb.getOperation(1)
        puts "control info = #{response_hash}"
        puts response_hash.size

        if response_hash.size == 0 then
          puts "response_hash null"
        else
	  xxx = response_hash.values
	  
          @operation_id = xxx[0]["operation_id"]
          @value = xxx[0]["value"]
           
          puts "operation_id = #{@operation_id} / value = #{@value}"

          # とりあえず2(完了)を入れる
          #   => sensorから取得した fan status を確認し @valueの値と一致すれば
          #      cloudに通知する
	  #response_hash = @clouddb.setOperationStatus(@operation_id,2)

          @setopeflag = 1

        end

      end

      # デバッグ用でテーブル内情報を表示
#     @localdb.loadSensingData

      puts "------ OUTPUT DATA ------"
      puts "limit max = {#@limit_max}"
      puts "limit min = {#@limit_min}"
      puts "value     = {#@value}"
      puts "-------------------------"

      @sensor.senddata(@limit_max.to_f,@limit_min.to_f,@value)

      # ループ周期
      sleep @atomic_interval
      @loop_count += 1
    end
  end
end


daemon_app = SensingControlDaemon.new
daemon_app.exec

