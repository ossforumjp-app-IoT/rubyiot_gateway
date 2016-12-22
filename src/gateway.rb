#!/usr/bin/ruby -Ku
# encoding: utf-8

require_relative "cloud_db_api"
require_relative "image_file"
require_relative "data_handler"
require_relative "sensor"
require "thread"
require "logger"

# Main処理のパラメータ
module MAIN_PARAMETER
  MAIN_LOOP = 1.0   # 1.0 second
  API_INTERVAL = 1.0 # 1.0 second
  UPLOAD_COST_TIME = 1.0 # second (time required to finish uploading image)
end

module PROCEDURE_NAME
  GET_DOOR_CMD = "get_door_cmd"
  GET_MONITORING_RANGE = "get_monitoring_range"
  GET_OPERATION = "get_operation"
  SET_SENSOR_ALERT = "set_sensor_alert"
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
    @log = Logger.new("/tmp/gateway.log")
    @log.level = Logger::DEBUG
    # DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
  end

  # 全体の流れ
  def main
    @log.info("#{__method__} start.")
    # method mappingsのHashを生成
    def_threads_mapping()
    begin
    while true
      data = {}

      data = @zigbee.recv()
      @log.debug("Receive data :#{data}")

      unless @data_hdr.id_h.has_key?(data["addr"]) then
        @data_hdr.register_id(data["addr"])
        @log.debug("MAC-SensorID table :#{@data_hdr.id_h}")
      end

      @api_worker[STORE_SENSING_DATA].call(data)

      @api_worker[SET_SENSOR_ALERT].call(
        data,
        @sensor.min,
        @sensor.max
      ) unless data["fail"].to_i.zero?

      # 画像ファイル確認のポーリング
      # ここはまとめてハンドラにすべき?
      if @data_hdr.file_search() == true then
         @log.info("Detecte image file.")
         @data_hdr.upload()
		 sleep MAIN_PARAMETER::UPLOAD_COST_TIME
         @data_hdr.delete()
	  end
	  
	  @api_worker[GET_DOOR_CMD].call(data)

      @api_worker[GET_MONITORING_RANGE].call(data)

#　　　       # 制御コマンド取得のポーリング
#      # ここはまとめてハンドラにすべき?
      @api_worker[GET_OPERATION].call(data)

      # TODO : wtf
      # Zigbeeでデータを送信
      l = @data_hdr.cmd.length
      l.times do
        q = @data_hdr.cmd.pop()
        result = @zigbee.send(q[2], @sensor.min, @sensor.max, q[0])
        @api_worker[SET_OPERATION_STATUS].call(q[1], result)
        @log.info("Send operation to sensor.")
        @log.debug("Send operation to sensor :#{q[2]} #{@sensor.min} #{@sensor.max} #{q[0]}")
      end

      sleep MAIN_PARAMETER::MAIN_LOOP

    end
    rescue Interrupt
      p "Program have finished by Ctrl+c"
	  sleep 3
    end

    @data_hdr.logout()

  end

  # 処理の全てThreadを無名method形でBlock化して、api_workerを用いてmethod mappingする
  def def_threads_mapping

    @api_worker[STORE_SENSING_DATA] = lambda {|data|
      Thread.new {@data_hdr.store_sensing_data(data)}
    }

    @api_worker[SET_SENSOR_ALERT] = lambda {|data, min, max|
      Thread.new {@data_hdr.set_sensor_alert(data, min, max)}
    }
    # TODO get_door_cmdで開錠コマンドを取得しAPIを続けるかどうかの判定
    # TODO get_door_cmdの引数
    # TODO cmd, idの取得方法
    @api_worker[GET_DOOR_CMD] = lambda {|data|
      Thread.new {
        # ATTENTION ここをwhile文にしてるのはコマンドの指示がない場合を
        # 考慮しているため。
		# TODO
        res = @data_hdr.get_door_cmd(data)
        ope_id = res[0]
        cmd = res[1]
        
		sleep MAIN_PARAMETER::API_INTERVAL
        
		@data_hdr.cmd.push([data["addr"], ope_id, cmd])
        @log.debug("Get door cmd :#{cmd}")
      }
    }

    @api_worker[GET_OPERATION] = lambda {|data|
        Thread.new {
          res = @data_hdr.get_operation()
          ope_id = res[0]
          cmd = res[1]
          @data_hdr.cmd.push([data["addr"], ope_id, cmd])
          @log.debug("Get LED cmd :#{cmd}")
        }
    }

    @api_worker[GET_MONITORING_RANGE] = lambda {|data|
      Thread.new {
        res = @data_hdr.get_monitoring_range(data)
        @sensor.min = res["min"].to_f
        @sensor.max = res["max"].to_f
        @log.debug("Monitoring range [min,max] :#{@sensor.min},#{@sensor.max}")
      }
    }

    @api_worker[SET_OPERATION_STATUS] = lambda {|id, result|
      Thread.new {@data_hdr.set_operation_status(id, result)}
    }
  end

#  private :main, :def_threads_mapping

end

g = Gateway.new(1)
g.def_threads_mapping()
g.main()
