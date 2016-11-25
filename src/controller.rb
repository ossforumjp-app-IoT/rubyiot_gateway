# An abstract class for all Controller
# @author FAE
# @abstract
class Controller

  MESS = "SYSTEM ERROR: method missing"
  def initalize; raise MESS; end

  def setFlag; raise MESS; end

  def getFlagStatus; raise MESS; end

end

# Enum DoorStatus
module DOOR_STATUS
  CLOSING = 0
  OPENING = 1
end

# ドアを制御するController
# @author FAE
# @attr_reader [Integer]        loopDelay   Controllerの
# @attr_reader [ZigbeeHandler]  zigbee
# @attr_reader [DoorStatus]     flag        ドアの状態　
class DoorController < Controller

  attr_reader :loopDelay, :zigbeeHandler, :flag
  # Controllerの初期化
  def initialize()
    @loopDelay =    1000 #ms
    @zigbeeHandler = ZigbeeHandler.new();
    @flag =          DOOR_STATUS::CLOSING
  end

  # ドアの状態を設定
  # @todo
  def closeDoor()
    @flag = DOOR_STATUS::CLOSING
    operateDoor()
  end

  def openDoor()
    @flag = DOOR_STATUS::OPENING
    operateDoor()
  end

  def getDoorStatus()
    return @flag
  end

  private :operateDoor

  def operateDoor()
    put case @flag
    when DOOR_STATUS::CLOSING
      puts "Close the door"
    when DOOR_STATUS::OPENING
      puts "Open the door"
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
# @attr_reader [Integer]        loopDelay   監視の周期（ms）
# @attr_reader [ZigbeeHandler]  zigbeeHanlder
# @attr_reader [BUTTON_STATUS]  btnStatus   ボタンの状況
class ButtonController < Controller

  attr_reader :loopDelay, :zigbee, :btnStatus
  def initialize()
    @loopDelay      = 100 #ms
    @zigbeeHandler  = ZigbeeHandler.new();
    @btnStatus      = BUTTON_STATUS::UNPUSHED
  end

  def getBtnStatus()
    btnStatus = @zigbeeHandler.getSomething();
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



