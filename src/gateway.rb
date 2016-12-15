#!/usr/bin/ruby -Ku

require_relative "cloud_db_api"
require_relative "image_file"
require_relative "data_handler"
require_relative "sensor"

# Main処理のパラメータ
module MAIN_PARAMETER
  MAIN_LOOP = 1.0   # 0.1 second
end

# RubyIoT 2016のMain処理

class Gateway

  def initialize(id)
    @id = id
    @file_hdr = ImageFile.new 
    @data_hdr = DataHandler.new(@id)
    @sensor = Sensor.new
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
      @data_hdr.store_sensing_data(data)


      if @file_hdr.search() == true then
         @data_hdr.upload(@file_hdr.filepath)

         operationThread = Thread.new {
            while do 
              sleep MAIN_PARAMETER::
              @file_hdr.get_door_cmd()
            end
         }
      end

      @z.send(data????)

      sleep MAIN_PARAMETER::MAIN_LOOP
    end
    rescue Interrupt
      p "Program have finished by Ctrl+c"
    end

  end

  def daemonlize
=begin
    @zfr = Thread.new {
      zfr = ZigbeeFrameReceiver.new
      while(1) do 
        @q_sdh = zfr.recv
      end
    }

    @btnThread = Thread.new {
      Thread.current["btnStatus"] = @btnCtl.getBtnStatus()
      sleep MAIN_PARAMETER::BTN_LOOP_DL
    }
    @btnThread.join
=end
  end
  
end

gw = Gateway.new(1)
gw.start_up()
