# A Parser class
# @author FAE

class DatParser

  MESS = "SYSTEM ERROR: method missing"
  def regsDatToStatus(rawData); raise MESS; end

end

# ボタンに関するデータ解析クラス
class BtnDatParser < DatParser

  # @param [String] rawData zigbee moduleで取得したbit列
  # @return [BUTTON_STATUS] ボタンの状態（Enum）
  def regsDatToStatus(rawData)
    # @todo : add parsing rule here
    return BUTTON_STATUS::PUSHED
  end
end

# ドアに関すデータ解析クラス
class DoorDatParser < DatParser

  # ドアのzigbee moduleから取得したbits列を解析、状態を取得
  # @param [String] rawData zigbee moduleで取得したbit列
  # @return [DOOR_STATUS] ドアの状態（Enum）
  def regsDatToStatus(rawData)
    # @todo : add parsing rule here
    return DOOR_STATUS::ANIMAL_DOOR_OPENING
  end

  # サーバから取得したjsonを解析して、operationを取得
  # @param [String] jsonData サーバから取得したjson値
  # @return [DOOR_OPERATION] ドアの動作（Enum）
  def jsonToOperation(jsonData)
    # @todo : add parsing rule here
    return DOOR_OPERATION::BOTH_DOOR_CLOSE
  end

  # 入力されたDOO_OPERATIONからbits列（zigbeeで書き込み）に変更する
  # @param [String] jsonData サーバから取得したjson値
  # @return [DOOR_OPERATION] ドアの動作（Enum）
  def operationToRegsDat(doorOperation)
    # todo : add parsing rule here
    return "A very long bite列"
  end

end
