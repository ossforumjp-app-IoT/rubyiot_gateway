#!/usr/bin/ruby -Ku

require_relative "cloud_db_api"
require_relative "image_file"
require_relative "data_handler"
require_relative "sensor"

# Main処理のパラメータ
module MAIN_PARAMETER
  MAIN_LOOP = 1.0   # 1.0 second
  API_INTERVAL = 1.0 # 1.0 second
end

module PROCEDURE_NAME
  GET_DOOR_CMD = "get_door_cmd"
  GET_MONITORING_RANGE = "get_monitoring_range"
  GET_OPERATION = "get_operation"
  NOTIFY_ALERT = "notify_alert"
  STORE_SENSING_DATA = "sotre_sensing_data"
end

# Gateway処理を行うクラス
# ATTENSTION センサをひとつしかもてない
# 複数所有する場合はArrayで複数のセンサオブジェクトを持たせる

class Gateway

  include PROCEDURE_NAME
  
  # Gatewayクラスの初期化
  # @param [Integer] @id GatewayのID
  # @param [DataHandler] @data_hdr DataHandlerオブジェト
  # @param [Sensor] @sensor Sensorオブジェクト
  # @param [Hash] @api クラウドのAPIのスレッドプール
  def initialize(id)
    @id = id
    # センサの温度異常値の初期値の渡し方を考えたほうがよい
    @sensor = Sensor.new(10.0, 30.0)
    @data_hdr = DataHandler.new(@id)
    @api_worker = Hash.new 
  end

  # 処理の全体
  def start_up
    daemonlize()
    main()
  end

  private
  # Gatewayのメインループ
  def main
    data = {}
    begin
    while true

      data = @z.recv()
      unless @id_h.has_key?(data["addr"]) then
        @data_hdr.register_id(data["addr"])
      end

      @api_worker[STORE_SENSING_DATA].call(data)

      @api_worker[NOTIFY_ALERT].call(data) unless data["fail"].to_i.zero?

      # 画像ファイル確認のポーリング
      # ここはまとめてハンドラにすべき?
      if @data_hdr.file_search() == true then
         @data_hdr.upload()
         @data_hdr.delete()
         @api_worker[GET_DOOR_CMD].call(data)
      end

      @data_hdr.get_monitoring_range(data)

　　　# 制御コマンド取得のポーリング
      # ここはまとめてハンドラにすべき?
      @data_hdr.get_operation()

      # Zigbeeでデータを送信
      l = @data_hdr.data.length
      l.times do
        q = @data_hdr.data.pop()
        result = @z.send(q[2], @sensor.min, @sensor.max, q[0])
        @api_worker[SET_OPERATION_STATUS].call(q[1], result)
      end
      sleep MAIN_PARAMETER::MAIN_LOOP

    end
    rescue Interrupt
      p "Program have finished by Ctrl+c"
    end

    @data_hdr.logout()

  end

  # クラウドAPIを実行する一部のメソッドをスレッド化して
  # 手続きで呼び出せるようにするメソッド
  def daemonlize

    @api_worker[STORE_SENSING_DATA] = lambda {|data| 
      Thread.new {@data_hdr.store_sensing_data(data)}
    }

    @api_worker[NOTIFY_ALERT] = lambda {|data|
      Thread.new {@data_hdr.notify_alert(data)}
    }

    # TODO get_door_cmdで開錠コマンドを取得しAPIを続けるかどうかの判定
    # TODO get_door_cmdの引数
    # TODO cmd, idの取得方法
    @api_worker[GET_DOOR_CMD] = lambda {|data|
      Thread.new {
        # ATTENTION ここをwhile文にしてるのはコマンドの指示がない場合を
        # 考慮しているため。
        begin
          ope_id, cmd = @data_hdr.get_door_cmd(XXX)
          sleep MAIN_PARAMETER::API_INTERVAL
        end while cmd == "XXX"
        @data_hdr.cmd.push((data["addr"], ope_id, cmd))
      }
    }
    
    @api_worker[GET_OPERATION] = lambda {
        Thread.new {
          ope_id, cmd = @data_hdr.get_operation()
          @data_hdr.cmd.push((data["addr"], ope_id, cmd))
        }
    }


    @api_worker[GET_MONITORING_RANGE] = lambda {|data|
      Thread.new {
        res = @data_hdr.get_monitoring_range(data)
        @sensor.min = res["min"]
        @sensor.max = res["max"]
      }
    }

    @api_worker[SET_OPERATION_STATUS] = lambda {|id, result|
      Thread.new {@data_hdr.set_operation_status(id, result)}
    }
  end
  
end


# Debug
if $0 == __FILE__ then

gw = Gateway.new(1)
gw.start_up()

end
