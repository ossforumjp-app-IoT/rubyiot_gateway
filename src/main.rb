require './controller'
require './datahandler'

module MAIN_PARAMETER
  MAIN_LOOP_DL    = 0.1   # 0.1 second
  BTN_LOOP_DL  = 0.1 # 0.1 second
  BTN_CTL_MAX_COUNT = 1
  BTN_STATUS
end

class Main

  attr_reader :btnCtl, :cameraCtl, :doorCtl, :dataHandler
  attr_reader :btnThread

  def initialize()
    @btnCtl     = ButtonController.new
    @cameraCtl  = CameraController.new
    @doorCtl    = DoorController.new
    @dataHandler= DataHandler.new
    @btnThread  = Thread.new {}
  end

  # RubyIot 2016のタスクのmain loop
  def main

    while true

      btnStatus = @btnThread["btnStatus"]

      if (btnStatus == BUTTON_STATUS::PUSHED)
        filePath = self.captureImg();

        if filePath != ""
          recogResult = self.recogImg(filePath)
          self.operateDoor()
        end

      end

      sleep MAIN_PARAMETER::MAIN_LOOP_DL

    end

  end

  private :daemonlizeBtnCtl, :captureImg, :recogImg, :operateDoor

  def daemonlizeBtnCtl
    @btnThread = Thread.new {
      Thread.current["btnStatus"] = @btnCtl.getBtnStatus()
      sleep MAIN_PARAMETER::BTN_LOOP_DL
    }
    @btnThread.join
  end

  def killBtnCtl
    @btnThread.kill
  end

  def captureImg
    imgData = @cameraCtl.captureImage()
    @cameraCtl.writeImageToDisk(imgData)
  end

  def recogImg(filePath)
    recogResult = @dataHandler.upload(filePath)
    return recogResult
  end

  def operateDoor
    @doorCtl.operateDoor()
  end

end


