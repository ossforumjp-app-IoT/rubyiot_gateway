#!/usr/bin/ruby -Ku
# encoding: utf-8

require_relative "cloud_db_api"
require_relative "data_handler"
require_relative "ble_handler"
require_relative "./picamera/picamera"
require "thread"
require "logger"

# Main処理のパラメータ
module MAIN_PARAMETER
  MAIN_LOOP = 0.1   # 0.1 second
  API_INTERVAL = 1.0 # 1.0 second
  UPLOAD_COST_TIME = 1.0 # second (time required to finish uploading image)
  AVERAGE_NUMBER = 10
  RSSI_THRESHOLD_OFFSET = 6
  THRESHOLD = -67
end

include MAIN_PARAMETER

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
    @camera = Picamera.new
    @rssi_threshold = 0.0
    @rssis = Array.new
    @ble_hdr = BleHandler.new
    @save_format = ".jpg"
    @file = Array.new
  end

  # Main
  def main
    @log.info("#{__method__} start.")

    #定常状態まで
    for num in 1..100 do
        @ble_hdr.get_rssi
=begin
	if num > 10 then
		sleep 5
	end
	puts num, @ble_hdr.get_rssi
=end
    end
#exit
    #閾値の決定
    ave = 0
    for num in 1..50 do
        ave = ave + @ble_hdr.get_rssi
    end
#    @rssi_threshold = ave/50 + RSSI_THRESHOLD_OFFSET
    @rssi_threshold = THRESHOLD + RSSI_THRESHOLD_OFFSET
    @log.info("Threshold: #{@rssi_threshold}")

    # RSSIの値を複数保存してからメイン文を実行
    for num in 1..AVERAGE_NUMBER do
        @rssis.push(@ble_hdr.get_rssi)
        sleep MAIN_PARAMETER::MAIN_LOOP
    end

    begin
    while true

      #puts @rssis

      # RSSI値の取得
      @rssis.push(@ble_hdr.get_rssi())
      # RSSI値の個数が平均を取る個数より1つ多いので最初に取得したものを削除
      @rssis.shift()

      rssi_ave = (@rssis.inject(:+))/AVERAGE_NUMBER

      #@log.info("rssi_ave: #{rssi_ave}")
      #@log.info("rssis:    #{@rssis}")
      if @rssi_threshold < rssi_ave then
         t = Thread.new {
           while true
             @ble_hdr.get_rssi()
           end
         }
         save_time = @camera.save()
         @log.info("Photographing!!! RSSI_AVE: #{rssi_ave}")
     	 #@log.info("rssi_ave: #{rssi_ave}")
   	 #@log.info("rssis:    #{@rssis}")

         @file[0] = save_time + "_0" + @save_format
         @file[1] = save_time + "_1" + @save_format
         @file[2] = save_time + "_2" + @save_format
         @file[3] = save_time + "_3" + @save_format
         @file[4] = save_time + "_4" + @save_format

         5.times do |i|
           while @data_hdr.file_search(@file[i])
                #@data_hdr.upload(@file[i])
		sleep 1
                @data_hdr.delete(@file[i])
           end
         end

         @rssis.clear()
         Thread.kill(t)
         for num in 1..AVERAGE_NUMBER do
             @rssis.push(@ble_hdr.get_rssi())
             sleep MAIN_PARAMETER::MAIN_LOOP
         end
      end

      #sleep MAIN_PARAMETER::MAIN_LOOP

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
