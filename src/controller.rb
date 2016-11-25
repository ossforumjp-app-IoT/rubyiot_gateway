# An abstract class for all Controller
# @author FAE
# @abstract
class Controller

  MESS = "SYSTEM ERROR: method missing"
  def initalize; raise MESS; end

  def setFlag; raise MESS; end

  def getFlagStatus; raise MESS; end

end

# Enum DOOR_STATUS ドアの状態
module DOOR_STATUS
  CLOSING = 0
  OPENING = 1
end

# Enum DOOR_OPERATION ドアの制御動作
module DOOR_OPERATION
  CLOSE = 0
  OPEN  = 1
end

# ドアを制御するController
# @author FAE
# @attr_reader [ZigbeeHandler]  zigbee
# @attr_reader [DoorStatus]     status        ドアの現在状態　
class DoorController < Controller

  attr_reader :zigbeeHandler, :flag
  # Controllerの初期化
  def initialize()
    @zigbeeHandler = ZigbeeHandler.new();
    @status        = DOOR_STATUS::CLOSING
  end

  # ドアの状態を設定
  # @todo
  def closeDoor()
    operateDoor(DOOR_OPERATION::CLOSE)
  end

  def openDoor()
    operateDoor(DOOR_OPERATION::OPEN)
  end

  def getDoorStatus()
    return @flag
  end

  private :operateDoor

  def operateDoor(operation_)
    put case operation_

    when DOOR_OPERATION::CLOSE
      if @flag == DOOR_STATUS::CLOSING
        puts "Door is already closing"
      else
        puts "Close the door"
        @flag = DOOR_STATUS::CLOSING
      end

    when DOOR_OPERATION::OPEN
      if @flag == DOOR_STATUS::OPENING
        puts "Door is alread open"
      else
        puts "Open the door"
        @flag = DOOR_STATUS::OPENING
      end

    end
  end
end

# Enum ButtonStatus
module BUTTON_STATUS
  UNPUSHED = 0
  PUSHED = 1
end

# ボータンの状況を監視するController
# @author FAE
# @attr_reader [ZigbeeHandler]  zigbeeHanlder
# @attr_reader [BUTTON_STATUS]  btnStatus   ボタンの状況
# @attr_reader [String]  btnUID   ボタンのUID
class ButtonController < Controller

  attr_reader :zigbee, :btnStatus, :btnUID
  def initialize()
    @zigbeeHandler  = ZigbeeHandler.new();
    @btnStatus      = BUTTON_STATUS::UNPUSHED
    @btnUID         = "UID of the button"
  end

  def getBtnStatus()
    return @zigbeeHandler.readData(@btnUID)
  end

end

module DEVICE_UIDS
  BUTTON = "button"
  ANOTHER = "other type of sensor"
end

# Dummy class for Zigbee module connected
class ZigbeeHandler
  # init the zigbee module
  def initialize()
  end

  # read Device data
  # @todo Zigbee module でデータをセンサから何か必要？仲里さんに頼む
  # @param  [String]      devUID Deviceの MAC address
  # @return [json/String] sensor data
  def readData(devUID)
    put case devUID
    when DEVICE_UIDS::BUTTON
      puts "read data from button"
    when DEVICE_UIDS::ANOTHER
      puts "read data from other type of sensor"
    end

  end

  # write data into devUIS using Zigbee module
  # @todo zigbee module でセンサにデータを書く際に何か必要？仲里さんに頼む
  # @param [String] devUIS Device's Mac address
  # @param [String] data   data which will be written into sesor
  def writeData(devUID, data_)
  end

  private :readButtonData, :readOtherData, :writeOtherData

  def readButtonData(devUID)
  end

  def readOtherData(devUID)
  end

  def writeOtherData(devUID, data_)
  end

end

class CameraController < Controller

  # memory location on disk
  MEM_DIRECTORY = "/dev/tmpfs"

  def initialize
  end

  def captureImage()
    # @todo : capture image
    imgData = "This is test image data"
    writeImageToDisk(imgData)
  end

  private :writeImageToDisk

  # write image data to memory /dev/shm or /dev/tmpfs
  # @param [String] imgData data of image in base64 format
  def writeImageToDisk(imgData)
    imgName = MEM_DIRECTORY + "/" + Time.now().to_s + ".png"
    File.open(imgName, 'wb') do|fid|
      fid.write(Base64.decode64(imgData))
    end
  end

end



