#!/usr/bin/ruby

require 'serialport'

# 受信データのフォーマット
# a,b,zxxx.x,c
# a:センサ状態 0 sensor:NG / controller:NG
#              1 sensor:OK / controller:NG
#              2 sensor:NG / controller:OK
#              3 sensor:OK / controller:OK
# b:FAN状態  0:停止 / 1:回転
# zxxx.x : 温度 z:+/-
# c:温度異常 0:正常 1:高温異常 2:低温異常
# 
# 送信データのフォーマット
# 0,A,ZXXX.0,YKKK.0 
# A:FAN制御  0:停止 / 1:回転

class ZigBeeReceiveFrame 
  def initialize()
    @sp = SerialPort.new('/dev/ttyUSB0', 115200, 8, 1, 0)
    @raw_data = Array.new
    @count = 0
    @outdata = Array.new

    @xbeestcode    = "7E"
    @xbeelen       = "00 1f"
    @xbeecmd       = "10"
    @xbeefrmid     = "00"
    # 以下LSI Xbeemodule
    #@xbeedstaddr   = "00 13 a2 00 40 b1 89 bc"
    # 以下社内Xbeemodule
    @xbeedstaddr   = "00 13 a2 00 40 66 10 7e"
    @xbeelocaldst  = "ff fe"
    @xbeeoption    = "00 00"

  end
  
  # センサの文字列データのみを取得する
  def get_data
    return @outdata.join
  end

  def send_data(data)
     sdata_str = data.unpack("H*")
     send_data_str = [@xbeecmd, @xbeefrmid, @xbeedstaddr ,@xbeelocaldst ,@xbeeoption, sdata_str].join(" ")
     send_data_ary = [send_data_str.tr(" ","")]
     send_data_bin = send_data_ary.pack("H*")
     sum = ~send_data_bin.sum(8) & 0xff
     sum_str = sprintf("%02x", sum)

     all_data_str = [@xbeestcode, @xbeelen, send_data_str, sum_str].join(" ")
     all_data_ary = [all_data_str.tr(" ","")]
     all_data_bin = all_data_ary.pack("H*")

     @sp.write(all_data_bin)
  end

  # fan状態を取得する
  def get_fan_status
    return @outdata.join[2,1]
  end

  # 温度を取得する
  def get_temp
    return @outdata.join[4,6]
  end

  # 異常状態を取得する
  def get_fail_status
    return @outdata.join[11,1]
  end

  # 装置状態を取得する
  def get_device_status
    return @outdata.join[0,1]
  end

  def recv_data_dummy()
    sleep 1
    if File.exist? "format.txt"
      stdata = File.read("format.txt")
      @outdata = stdata.split("")
    else
      stdata = "3,0,+16.8"
      @outdata = stdata.split("")
    end
  end

  def recv_data()
#    @sp.flush_input
    @count = 0
    length = 100
    loop do
      # 文字を1byte読み込み
      @raw_data[@count] = @sp.read(1)
p @raw_data[@count]
      if @count == 0 then
        if @raw_data[@count] != '~' then
           next
        end
      end

      # データ長チェック
      if @count == 2 then
        length_str = @raw_data[1,2]
        tmp2 = length_str.join
        tmp1 = tmp2.unpack("n*")
        puts "length = #{tmp1}"
        length = tmp1[0]
        length = length + 2
#        p "length = #{length}"
        if length != 26 then
          puts "data length error"
          @count = 0
          next
        end
      end

      # センサ情報が正常の場合、データを復帰する
      @count = @count+1
      if @count > 2 then
        if @count > length then
          chknum = @raw_data[14,1]
          if chknum != ["3"] then
            @count = 0
            puts "sensor error st= #{chknum}"
            @sp.flush_input
            next
          end
          break
        end
      end

    end
    @outdata = @raw_data[14,12]
    #return textstr
    return 1
  end
end


