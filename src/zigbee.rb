#!/usr/bin/ruby -Ku

require "serialport"
require "yaml"
require_relative "serialdummy"

# Zigbeeを取り扱うクラスのパラメータ
module ZIGBEE_PARAM
  SENSOR_RECV_LOOP = 0.1
end

 # Zigbeeのフレームを作成するクラス
class ZigbeeFrameCreater

  def initialize(xbee)
    @cmd = xbee["cmd"].tr(" ","")
    @frmid = xbee["frmid"].tr(" ","")
    @local = xbee["localdst"].tr(" ","")
    @option = xbee["option"].tr(" ","")
    @stcode = xbee["stcode"].tr(" ","")
    @len = xbee["len"].tr(" ","")
  end

  # センサに送信するZigbeeフレームを作成する
  # [Reserved(0)],[0/1],[+/-][XXX.X],[+/-][XXX.X]
  # dataパラメータは本来ここでは作らないべき?
  # @param [String] data 上記フォーマットのフレーム
  # @param [String] raw_data Zigbeeフレーム
  # @param [Intger] cmd FAN/DOORの制御コマンド
  # @param [Float] max_temp 高温異常温度値
  # @param [Float] min_temp 低温異常温度値
  # @param [String] addr 送信先のZigbeeモジュールのMAC Address 
  def create(cmd, min_temp, max_temp, addr)
    def sign(num)
      return (num > 0) ? "+" : "-"  
    end

    def check_sum(*args)
      return sprintf("%02x", (~([args.inject(:+)].pack("H*").sum(8)) & 0xff))
    end

    data = ("0" + "," +
            "#{cmd}" + "," +
            sign(max_temp) + 
            sprintf("0%2.1f",max_temp.abs) + "," +
            sign(min_temp) +
            sprintf("0%2.1f",min_temp.abs)).unpack("H*").join
    raw_data = @stcode + @len + @cmd + 
               @frmid + addr + @local + 
               @option + data + 
               check_sum(@cmd, @frmid, addr, @local, @option, data)
    return [raw_data].pack("H*")
  end 

end


# Zigbeeのフレームを解析するクラス
class ZigbeeFrameParser

  def initialize
  end

  # Raw dataをパースするメソッド
  # 本来はこのメソッドはSensorというクラスに存在するべき？
  # @param [Hash] data パースしたデータを格納する変数
  def parse(raw_data)
    data = {}
    # MAC Addressの取得
    data["addr"] = get_addr(raw_data)
    # データの取り出し
    data["fan"] = get_fan_status(raw_data)
    data["temp"] = get_temp(raw_data)
    data["fail"] = get_fail_status(raw_data)
    data["status"] = get_device_status(raw_data)
  
    return data
  end

  # MAC Addressの取り出し
  # "13"を追加する理由はZigbeeのAPIモードが
  # 2になっておりESC処理で落ちているため。
  # unpack("H*")はStringをASCII文字列の配列に変換するメソッド
  # @param [Array] data Zigbeeフレームのbyte列
  # @return [String] ZigbeeのMAC Address
  def get_addr(data)
    addr = (data.join)[4,1].unpack("H*") + [13] +
          (data.join)[5,6].unpack("H*")
    return addr.join
  end

  # デバイス状態の取得
  # @return [String] デバイス状態
  def get_device_status(data)
    return data[14,1].join
  end

  # FAN状態の取得
  # @return [String] FANの状態
  def get_fan_status(data)
    return data[14,1].join
  end

  # 温度の取得
  # @return [String] 温度
  def get_temp(data)
    return (data.join)[18,6].to_f
  end

  # 異常状態の取得
  # @return [String] 異常状態
  def get_fail_status(data)
    return data[25,1].join
  end

end


# Zigbeeを取り扱うクラス
class Zigbee
  @@xbee = YAML.load_file "./xbee.yml"

  def initialize
    spconf = @@xbee["serialport"]
    begin
    if spconf["device"] == "dummy"
      @sp = SerialDummyPort.new
    else
      @sp = SerialPort.new(spconf["device"], spconf["boudrate"],
                           spconf["databits"], spconf["stopbits"], 
                           spconf["parity"])
    end
    rescue => e
      p '---------------------------------'
      p "SerialPort open error"
      p e.message
      p '---------------------------------'
    end

    @zigbee_frame_parser = ZigbeeFrameParser.new
    @zigbee_frame_creater = ZigbeeFrameCreater.new(@@xbee)
    #@addr = nil
  end

  def parse(raw_data)
    return @zigbee_frame_parser.parse(raw_data)
  end

  def create(cmd, min_temp, max_temp, addr)
    return @zigbee_frame_creater.create(cmd, min_temp, max_temp, addr)
  end

  # センサのZigbeeから送られてくる1フレーム分を受信するメソッド
  # @param [Array] data センサから送られてくるデータ列
  # @param [Array] mac ZigbeeモジュールのMAC Address
  # @return [Array] (mac + data)
  # @comment 誰かもう少しキレイにして
  def recv
    @sp.flush_input
    count = 0
    length = 100
    raw_data = Array.new

    loop do
      # 文字を1byte読み込み
      raw_data[count] = @sp.read(1)
      if count == 0 then
        if raw_data[count] != "~" then
          next
        end
      end
  
      # データ長チェック
      if count == 2 then
        length_str = raw_data[1,2]
        tmp2 = length_str.join
        tmp1 = tmp2.unpack("n*")
        length = tmp1[0]
        length = length + 2
        if length != 26 then
          puts "data length error"
          count = 0
          next
        end
      end
    
      # センサ情報が正常の場合、データを復帰する
      count = count + 1
      if count > 2 then
        if count > length then
          chknum = raw_data[14,1]
          if chknum != ["3"] then
            count = 0
            p "sensor error st= #{chknum}"
            @sp.flush_input  
            next
          end
        break
        end
      end
    
    end # loop do

    return parse(raw_data)

  end

  def send(cmd, min, max, addr)
    begin
    frame = create(cmd, min, max, addr)
    @sp.write(frame)
    result = 0
    rescue => e
      p '---------------------------------'
      p "SerialPort write error"
      p e.message
      p '---------------------------------'
      result = 1
    end
    return result
  end
 
end

# DEBUG
if $0 == __FILE__ then
  z = Zigbee.new
  p z.recv()
  p z.recv()["addr"]
  z.send(1, 30.0, 11.0, z.recv()["addr"])
end

