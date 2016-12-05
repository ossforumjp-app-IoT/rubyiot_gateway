require './datParser'

# An abstract class for all Controller
# @author FAE
# @abstract
# @attr_reader [DEV_UIDS]       devUID           zigbeeセンサーのUID
class Controller

  attr_reader :devUID

  MESS = "SYSTEM ERROR: method missing"
  def initalize; raise MESS; end

  def getStatus; raise MESS; end

end

# Enum DeviceのUID
module DEVICE_UIDS
  BUTTON  = "BUTTON UID"
  DOOR    = "DOOR UID"
  ANOTHER = "OTHER TYPE OF SENSOR's UID"
end

# @todo ドア毎のIDとドアの状態を分けたほうが良いか
# Enum DOOR_STATUS ドアの状態を定義
module DOOR_STATUS
  BOTH_DOOR_CLOSING = 0
  ANIMAL_DOOR_OPENING = 1
  HUMAN_DOOR_OPENING = 2
  BOTH_DOOR_OPENING = 3
end

# Enum DOOR_OPERATION ドアの制御動作を定義
module DOOR_OPERATION
  BOTH_DOOR_CLOSE = 0
  ANIMAL_DOOR_OPEN = 1 #人用のドアは閉める
  HUMAN_DOOR_OPEN = 2   #動物用のドアは閉める
  BOTH_DOOR_OPEN = 3
end

# ドアを制御するController
# @author FAE
# @attr_reader [DOOR_STATUS]    doorStatus        ドアの現在状況
# @attr_reader [DoorDatParser]  doorDatParser     ドアに関するデータ解析
# @attr_reader [ZigbeeHandler]  zigbeeHandler     zigbeeモジュール
class DoorController < Controller

  attr_reader :doorStatus, :doorDatParser, :zigbee
  # Controllerの初期化
  def initialize(devUID)
    @devUID        = devUID
    @doorStatus    = DOOR_STATUS::BOTH_DOOR_CLOSING
    @doorDatParser = DoorDatParser.new
    @zigbeeHandler = ZigbeeHandler.new
  end

  # ドアの状態を取得 : Dummy method
  def getStatus

    zigbeeRawBits = @zigbeeHandler.readData(@devUID)
    return @doorDatParser.regsDatToStatus(zigbeeRawBits)

  end

  # ドアを制御する : Dummy method
  # @param [String] operation サーバから取得した認識値（json 形）
  def operateDoor(jsonData)

    operation = @doorDatParser.jsonToOperation(jsonData);

    operationRawBits = @doorDatParser.operationToRegsDat(operation);

    @zigbeeHandler.writeData(@devUID, operationRawBits)

    # 動作後に状態を更新

    case operation
    when DOOR_OPERATION::BOTH_DOOR_CLOSE
      if @doorStatus == DOOR_STATUS::BOTH_DOOR_CLOSING
        puts "Both door is already close"
      else
        puts "Close the both door"
        @doorStatus = DOOR_STATUS::BOTH_DOOR_CLOSING
      end

    when DOOR_OPERATION::ANIMAL_DOOR_OPEN
      if @doorStatus == DOOR_STATUS::ANIMAL_DOOR_OPENING
        puts "Animal door is already open"
      else
        puts "Open the animal door"
        @doorStatus = DOOR_STATUS::ANIMAL_DOOR_OPENING
      end

    when DOOR_OPERATION::HUMAN_DOOR_OPEN
      if @doorStatus == DOOR_STATUS::HUMAN_DOOR_OPENING
        puts "Door is already open"
      else
        puts "Open the door"
        @doorStatus = DOOR_STATUS::HUMAN_DOOR_OPENING
      end

    when DOOR_OPERATION::BOTH_DOOR_OPEN
      if @doorStatus == DOOR_STATUS::BOTH_DOOR_OPENING
        puts "Door is already open"
      else
        puts "Open the door"
        @doorStatus = DOOR_STATUS::BOTH_DOOR_OPENING
      end
    end

  end

end


# Enum ButtonStatus
module BUTTON_STATUS
  UNPUSHED  = 0
  PUSHED    = 1
end

# ボータンの状況を監視するController
# @author FAE
# @attr_reader [BUTTON_STATUS]    btnStatus     ボタンの現在状況
# @attr_reader [BtnDatParser]     btnDatParser  ボタンに関するデータを解析
# @attr_reader [ZigbeeHandler]    zigbeeHanlder zigbee Unit
class ButtonController < Controller

  attr_reader :btnStatus, :btnDatParser, :zigbee
  def initialize
    @btnStatus      = BUTTON_STATUS::UNPUSHED
    @btnDatParser   = BtnDatParser.new
    @zigbee         = ZigbeeHandler.new();
  end

  # zigbeeでボタンの状態を取得
  def getStatus
    rawBits =  @zigbeeHandler.readData(@btnUID)
    return @btnDatParser.regsDatToStatus(rawBits)
  end

end

# zigbee（無線）でDeviceの情報を取得
class ZigbeeHandler
  # init the zigbee module
  def initialize
  end

  # Deviceの情報を取得（devUIDによる読み方が違う
  # @todo Zigbee module でセンサからデータを読む際に何か必要？仲里さんに頼む
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
  # @todo どのセンサを使うかに応じて、write～Dataの部分のメソッドを作成する
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
