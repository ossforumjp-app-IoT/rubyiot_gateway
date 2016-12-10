
require "zigbee"
require "data_handler"

# Main処理のパラメータ
module MAIN_PARAMETER
  MAIN_LOOP = 0.1   # 0.1 second
end

# RubyIoT 2016のMain処理

class Main

  def initialize
    @zfr = Thread.new {}
    @q = SizeQueue.new(100)
    @sdh = SensingDataHandler.new(@q)
  end

  # 処理の全体
  def exec
    self.daemonlize()
    self.mainLoop()
  end

  private :mainLoop

  # RubyIot 2016のタスクのmain loop
  def mainLoop

    begin
    while true

      @sdh.store_sensing_data

      if (btnStatus == BUTTON_STATUS::PUSHED)
        filePath = self.captureImg();

        if filePath != ""
          recogResult = self.recogImg(filePath)
          self.operateDoor(recogResult)
        end

      end

      sleep MAIN_PARAMETER::MAIN_LOOP

    end
    rescue Interrupt
      p "Program have finished by Ctrl+c"
    end

  end

  def daemonlize
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
  end

end

main = Main.new
main.exec()
