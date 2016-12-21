#!/usr/bin/ruby -Ku

require_relative "cloud_db_api"
require_relative "image_file"
require_relative "data_handler"
require_relative "sensor"
require "thread"

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
  STORE_SENSING_DATA = "store_sensing_data"
  SET_OPERATION_STATUS = "set_operation_status"
end

# Gateway処理を行うクラス
# ATTENSTION センサをひとつしかもてない
# 複数所有する場合はArrayで複数のセンサオブジェクトを持たせる
# @attr [Integer] id GatewayのID
# @attr_reader [Sensor] sensor Sensorオブジェクト
# @attr_reader [DataHandler] data_hdr DataHandlerオブジェト
# @attr_reader [Hash] api_worker クラウドとやり取りでのmethod mapping hash
# @attr_reader  [Zigbee] zigbee Zigbee moduleとやり取りUnit
class Gateway

  attr :id
  attr_reader :sensor, :data_hdr, :api_worker, :zigbee

  include PROCEDURE_NAME

  # Gatewayクラスの初期化
  # @param [Integer] @id GatewayのID
  def initialize(id)
    @id = id
    # センサの温度異常値の初期値の渡し方を考えたほうがよい
    @sensor = Sensor.new(10.0, 30.0)
    @data_hdr = DataHandler.new(@id)
    @api_worker = Hash.new
    @zigbee = Zigbee.new
  end

  # 全体の流れ
  def main
    data = {}
    # method mappingsのHashを生成
    def_threads_mapping()
    begin
    while true

#      data = @zigbee.recv()
      data = {"dev_status"=>3, "temperature"=>23.1, "fan_status"=>0, "fail_status"=>0, "addr"=>"0013a20040b189bc"}
      # TODO DataHandler の　id_h の初期化は　{} なのでエラーが発生
#      unless @data_hdr.id_h.has_key?(data["addr"]) then
#        @data_hdr.register_id(data["addr"])
#      end

      @api_worker[STORE_SENSING_DATA].call(data)

      @api_worker[NOTIFY_ALERT].call(
        data,
        @sensor.min,
        @sensor.max
      ) unless data["fail_status"].to_i.zero?

      # 画像ファイル確認のポーリング
      # ここはまとめてハンドラにすべき?
      if @data_hdr.file_search() == true then
         @data_hdr.upload()
         @data_hdr.delete()
         @api_worker[GET_DOOR_CMD].call(data)
      end

      @api_worker[GET_MONITORING_RANGE].call(data)

#　　　       # 制御コマンド取得のポーリング
#      # ここはまとめてハンドラにすべき?
      @api_worker[GET_OPERATION].call()

      # TODO : wtf
      # Zigbeeでデータを送信
      l = @data_hdr.cmd.length
      l.times do
        q = @data_hdr.cmd.pop()
        result = @zigbee.send(q[2], @sensor.min, @sensor.max, q[0])
        @api_worker[SET_OPERATION_STATUS].call(q[1], result)
      end

      sleep MAIN_PARAMETER::MAIN_LOOP

    end
    rescue Interrupt
      p "Program have finished by Ctrl+c"
    end

    @data_hdr.logout()

  end

  # 処理の全てThreadを無名method形でBlock化して、api_workerを用いてmethod mappingする
  def def_threads_mapping

    @api_worker[STORE_SENSING_DATA] = lambda {|data|
      Thread.new {@data_hdr.store_sensing_data(data)}
    }

    @api_worker[NOTIFY_ALERT] = lambda {|data, min, max|
      Thread.new {@data_hdr.notify_alert(data, min, max)}
    }
    # TODO get_door_cmdで開錠コマンドを取得しAPIを続けるかどうかの判定
    # TODO get_door_cmdの引数
    # TODO cmd, idの取得方法
    @api_worker[GET_DOOR_CMD] = lambda {|data|
      Thread.new {
        # ATTENTION ここをwhile文にしてるのはコマンドの指示がない場合を
        # 考慮しているため。
        begin
          ope_id, cmd = @data_hdr.get_door_cmd(xxx)
          sleep MAIN_PARAMETER::API_INTERVAL
        end while cmd == "xxx"
        @data_hdr.cmd.push([data["addr"], ope_id, cmd])
      }
    }

    @api_worker[GET_OPERATION] = lambda {
        Thread.new {
          res = @data_hdr.get_operation()
          ope_id = res["0"]
          cmd = res["1"]
          @data_hdr.cmd.push([data["addr"], ope_id, cmd])
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

#  private :main, :def_threads_mapping

end

