#!/usr/bin/ruby -Ku
# encoding: utf-8

require_relative "cloud_db_api"
require_relative "data_handler"
require_relative "ble_handler"
#require_relative "./picamera/picamera"
require "thread"
require "logger"

# Main処理のパラメータ
module MAIN_PARAMETER
  MAIN_LOOP = 0.1   # 0.1 second
  API_INTERVAL = 1.0 # 1.0 second
  UPLOAD_COST_TIME = 1.0 # second (time required to finish uploading image)
  AVERAGE_NUMBER = 10
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
  attr_reader :data_hdr
  # Gatewayクラスの初期化
  # @param [Integer] @id GatewayのID
  def initialize(id)
    @id = id
    @data_hdr = DataHandler.new(@id)
    @log = Logger.new("/tmp/gateway.log")
    @log.level = Logger::DEBUG
    # DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
    #@camera = Picamera.new
    @rssi_threshold = -58
    @rssis = Array.new
    @ble_hdr = BleHandler.new
  end

  # Main
  def main
    @log.info("#{__method__} start.")

    # RSSIの値を複数保存してからメイン文を実行
    for num in 1..AVERAGE_NUMBER do
        @rssis.push(@ble_hdr.get_rssi())
        sleep MAIN_PARAMETER::MAIN_LOOP
    end

    begin
    while true

      puts @rssis

      # RSSI値の取得
      @rssis.push(@ble_hdr.get_rssi())
      # RSSI値の個数が平均を取る個数より1つ多いので最初に取得したものを削除
      @rssis.shift()

      rssi_ave = @rssis.inject(:+)

      if @rssi_threshold < rssi_ave then
         #@camera.save()
         
         while @data_hdr.file_search()
           5.times do |i|
                @data_hdr.upload(i.to_s + "jpg")
                @data_hdr.delete(i.to_s + "jpg")
           end
         end

         @rssis.clear()
         for num in 1..AVERAGE_NUMBER do
             @rssis.push(@ble_hdr.get_rssi())
             sleep MAIN_PARAMETER::MAIN_LOOP
         end
      end

      sleep MAIN_PARAMETER::MAIN_LOOP

    end
    rescue Interrupt
      p "Program have been stopped by Ctrl+c"
	  sleep 3
    end

    @data_hdr.logout()

  end

end

g = Gateway.new(1)
#g.def_threads_mapping()
g.main()
