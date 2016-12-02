# An abstract class for all Controller
# @author FAE
# @abstract
class Controller

  MESS = "SYSTEM ERROR: method missing"
  def initalize; raise MESS; end

  def getStatus; raise MESS; end

end


# Enum DOOR_STATUS ドアの状態を定義
module DOOR_STATUS
  CLOSING = 0
  OPENING = 1
end

# Enum DOOR_OPERATION ドアの制御動作を定義
module DOOR_OPERATION
  CLOSE = 0
  OPEN  = 1
end

# ドアを制御するController
# @author FAE
# @attr_reader [ZigbeeHandler]  zigbeeHandler          zigbeeモジュール
# @attr_reader [DoorStatus]     doorStatus        ドアの現在状態
class DoorController < Controller

  attr_reader :zigbeeHandler, :doorStatus
  # Controllerの初期化
  def initialize
    @zigbeeHandler = ZigbeeHandler.new
    @doorStatus    = DOOR_STATUS::CLOSING
  end

  # ドアの状態を取得 : Dummy method
  def getStatus
    return @doorStatus
  end

  # ドアを制御する : Dummy method
  def operateDoor(operation_)

    case operation_
    when DOOR_OPERATION::CLOSE
      if @doorStatus == DOOR_STATUS::CLOSING
        puts "Door is already closing"
      else
        puts "Close the door"
        @doorStatus = DOOR_STATUS::CLOSING
        self.closeDoor()
      end

    when DOOR_OPERATION::OPEN
      if @doorStatus == DOOR_STATUS::OPENING
        puts "Door is already open"
      else
        puts "Open the door"
        @doorStatus = DOOR_STATUS::OPENING
        self.openDoor()
      end
    end

  end

  private :closeDoor
  private :openDoor

  # ドアを閉める
  def closeDoor

  end

  # ドアを開ける
  def openDoor

  end

end


# Enum ButtonStatus
module BUTTON_STATUS
  UNPUSHED  = 0
  PUSHED    = 1
end

# ボータンの状況を監視するController
# @author FAE
# @attr_reader [ZigbeeHandler]    zigbeeHanlder zigbee Unit
# @attr_reader [BUTTON_STATUS]    btnStatus     ボタンの現在状況
# @attr_reader [String]           btnUID        ボタンのUID（通信するため）
class ButtonController < Controller

  attr_reader :zigbee, :btnStatus, :btnUID
  def initialize
    @zigbeeHandler  = ZigbeeHandler.new();
    @btnStatus      = BUTTON_STATUS::UNPUSHED
    @btnUID         = "UID of the button"
  end

  # 無線経由でボタンの状態を取得
  def getStatus
    return @zigbeeHandler.readData(@btnUID)
  end

end

# Enum DeviceのUID
module DEVICE_UIDS
  BUTTON = "button"
  ANOTHER = "other type of sensor"
end

# zigbee（無線）でDeviceの情報を取得
class ZigbeeHandler
  # init the zigbee module
  def initialize
  end

  # Deviceの情報を取得（devUIDによる読み方が違う
  # @todo Zigbee module でデータをセンサから何か必要？仲里さんに頼む
  # @param  [String]      devUID Deviceの UID
  # @return [json/String] sensor data
  def readData(devUID)
    case devUID
    when DEVICE_UIDS::BUTTON
      puts "read data from button"
      return readButtonData(devUID)
    when DEVICE_UIDS::ANOTHER
      puts "read data from other type of sensor"
      return readOtherData(devUID)
    end

  end

  # Deviceに情報を書く（devUIDによる書き方が違う）
  # @todo zigbee module でセンサにデータを書く際に何か必要？仲里さんに頼む
  # @param [String] devUID DeviceのUID
  # @param [String] data   Deviceに書くデータ
  def writeData(devUID, data)
    case devUID
    when DEVICE_UIDS::ANOTHER
      puts "write data to other type of sensor"
      return writeOtherData(devUID, data)
    end
  end

  private :readButtonData, :readOtherData, :writeOtherData

  def readButtonData(devUID)
    return "Status of Button is read from #{devUID}"
  end

  def readOtherData(devUID)
    return "Data　of other is read from #{devUID} "
  end

  def writeOtherData(devUID, data)
    return "#{data} is wrote into other type of sensor #{devUID}"
  end

end

module CAMERA_STATUS
  AVAILABLE = 0
  UNAVAILABLE = 1
end

class CameraController < Controller

  # memory location on disk
  MEM_DIRECTORY = "/dev/tmpfs"

  # カメラ初期化
  def initialize
  end

  # カメラの状態を取得
  def getStatus
    return CAMERA_STATUS::AVAILABLE;
  end

  def captureImage
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
