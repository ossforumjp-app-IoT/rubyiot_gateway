require './controller'
require './datahandler'

# Main処理のパラメータ
module MAIN_PARAMETER
  MAIN_LOOP_DL    = 0.1   # 0.1 second
  BTN_LOOP_DL  = 0.1 # 0.1 second
  BTN_CTL_MAX_COUNT = 1
  BTN_STATUS
end

# RubyIoT 2016のMain処理
# @param attr_reader [ButtonController] btnCtl      ボタンの状態を取得Controller
# @param attr_reader [CameraController] cameraCtl   カメラを制御するController
# @param attr_reader [DoorController] doorCtl       ドア制御するController
# @param attr_reader [Datahandler] dataHandler      Databaseにデータ送信、認識結果を取得Controller
class Main

  attr_reader :btnCtl, :cameraCtl, :doorCtl, :dataHandler
  attr_reader :btnThread

  # Controllerを初期化
  def initialize()
    @btnCtl     = ButtonController.new
    @cameraCtl  = CameraController.new
    @doorCtl    = DoorController.new
    @dataHandler= DataHandler.new
    @btnThread  = Thread.new {}
  end

  # 処理の全体
  def exec
    self.daemonlizeBtnCtl()
    self.main()
  end

  private :daemonlizeBtnCtl, :captureImg, :recogImg, :operateDoor, :main

  # RubyIot 2016のタスクのmain loop
  def main

    while true

      btnStatus = @btnThread["btnStatus"]

      if (btnStatus == BUTTON_STATUS::PUSHED)
        filePath = self.captureImg();

        if filePath != ""
          recogResult = self.recogImg(filePath)
          self.operateDoor(recogResult)
        end

      end

      sleep MAIN_PARAMETER::MAIN_LOOP_DL

    end

  end

  # ボタンのControllerをbackgroundに移動
  def daemonlizeBtnCtl
    @btnThread = Thread.new {
      Thread.current["btnStatus"] = @btnCtl.getBtnStatus()
      sleep MAIN_PARAMETER::BTN_LOOP_DL
    }
    @btnThread.join
  end

  # ボタンのControllerを止める
  def killBtnCtl
    @btnThread.kill
  end

  # 画像を撮影して、RaspberryPIのローカルメモリに保存
  def captureImg
    imgData = @cameraCtl.captureImage()
    @cameraCtl.writeImageToDisk(imgData)
  end

  #　画像をサーバにアップロードして、認識する
  # @param [String] filePath 画像のpath
  # @return [String/json] 認識結果 {"devUID":{"operation_id":"yyy", "value":"操作値"}}
  def recogImg(filePath)
    recogResult = @dataHandler.upload(filePath)
    return recogResult
  end

  # ドアの制御する
  def operateDoor(recogResult)
    @doorCtl.operateDoor(recogResult)
  end

end

main = Main.new
main.exec()
