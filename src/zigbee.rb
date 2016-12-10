
require "serialport"
require "yaml"


class ZigbeeFrameParser

  def initialize
    
  end

  def get_fan_status()
    return 
  end

end

class ZigbeeFrameReceiver
  @@xbee = YAML.load_file "./xbee.yml"

  def initialize
    @zigbee_parser = ZigbeeFrameParser.new

    spconf = @@xbee["serialport"]
    begin
    if spconf["device"] == "dummy"
      @sp = SerialDummyFile.new
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
  end

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

    data = raw_data.join[4,1].unpack("H*").pop + "13" +
           raw_data.join[5,6].unpack("H*").pop +
           raw_data[14,1] +
           raw_data[16,1] +
           raw_data.join[18,6].split(" ") +
           raw_data[25,1]

    return data

  end
 
end


# DEBUG

if $0 == __FILE__ then
  zfr = ZigbeeFrameReceiver.new

end


