#!/usr/bin/ruby

require 'serialport'
require_relative './serialdummy'

require 'yaml'

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


class ZigbeeHandler
  
  def initialize()

  end
 
  def readRegs()

  end 

  def writeRegs()

  end

class ZigBeeReceiveFrame
  @@xbee = YAML.load_file './xbee.yml'

  def initialize
    spconf = @@xbee["serialport"]
		begin
	    if spconf["device"] == "dummy"
	      @sp = SerialDummyFile.new
	    else
	      @sp = SerialPort.new(spconf["device"], spconf["boudrate"], spconf["databits"], spconf["stopbits"], spconf["parity"])
		#@sp.flow_control = SerialPort::NONE
			end
		rescue
			puts "SerialPort open error"
   	end

    @raw_data = Array.new
    @count = 0
    @outdata = Array.new
	#	@f = File.open('format.txt', "r")
  end

  # センサのデータを文字列に変換して取得する
  #   @return [String] 文字列に変換したセンサのデータ
  def get_data
    return @outdata.join
  end

  # センサのデータを送信する
  #   @param [String] data
  #   @param [Numeric] addr
  def send_data(data,addr)
	puts "#{addr} #####################"
     sdata_str = data.unpack("H*")
     #send_data_str = [@@xbee["cmd"], @@xbee["frmid"], @@xbee["dstaddr"] ,@@xbee["localdst"] ,@@xbee["option"], sdata_str].join(" ")
     send_data_str = [@@xbee["cmd"], @@xbee["frmid"], addr ,@@xbee["localdst"] ,@@xbee["option"], sdata_str].join(" ")
     send_data_ary = [send_data_str.tr(" ","")]
     send_data_bin = send_data_ary.pack("H*")
     sum = ~send_data_bin.sum(8) & 0xff
     sum_str = sprintf("%02x", sum)

     all_data_str = [@@xbee["stcode"], @@xbee["len"], send_data_str, sum_str].join(" ")
puts "#{all_data_str}************************************"
     all_data_ary = [all_data_str.tr(" ","")]
puts "#{all_data_ary}"
     all_data_bin = all_data_ary.pack("H*")
	puts "#{all_data_bin}"
     @sp.write(all_data_bin)
  end

  # fan状態を取得する
  #   @return [Integer] ファンの状態を取得
  def get_fan_status
    #return @outdata.join[2,1]
    return @outdata[2]	#DEBUG
  end

  # 温度を取得する
  #   @return [Float] 温度を取得
  def get_temp
    #return @outdata.join[4,6]
    return @outdata[3] #DEBUG
  end

  # 異常状態を取得する
  #   @return [Numeric] センサの温度の状態を取得
  def get_fail_status
    #return @outdata.join[11,1]
    return @outdata[4] #DEBUG
  end

  # 装置状態を取得する
  #   @return [Numeric] センサの状態を取得
  def get_device_status
    #return @outdata.join[0,1]
    return @outdata[1]	#DEBUG
  end

	# Get mac addr of the device
  #   @return [Integer] センサデバイスのMACアドレスを取得する
	def get_addr
		return @outdata[0]
		#return addr[0,1].unpack("H*")
	end

  # センサからデータを受け取る
  #   @return [Integer]
  def recv_data_dummy()
		@outdata = @f.gets.chomp
=begin
    sleep 1
    if File.exist? "format.txt"
      stdata = File.read("format.txt")
      @outdata = stdata.split("")
    else
      stdata = "3,0,+16.8"
      @outdata = stdata.split("")
    end
=end
  end

  # センサからデータを受け取り、読み出す
  def recv_data()
    @sp.flush_input
    @count = 0
    length = 100
    loop do
      # 文字を1byte読み込み
      @raw_data[@count] = @sp.read(1)
#p @raw_data[@count]
#p @count
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
        #puts "length = #{tmp1}"
        length = tmp1[0]
        length = length + 2
        p "length = #{length}"
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
          #chknum = @raw_data[16,1]
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

    #@outdata = @raw_data[14,12]
     @outdata = []
puts "#{@raw_data}########################################RAWDATA"
    tmpdata = nil
    tmpdata = @raw_data.join[4,1].unpack("H*").pop + "13" + @raw_data.join[5,6].unpack("H*").pop
    #puts tmpdata
    #@outdata = @raw_data.join[4,8].unpack("H*") + @raw_data[14,1] + @raw_data[16,1] + @raw_data.join[18,6].split(" ") + @raw_data[26,1]
    #@outdata = @raw_data.join[4,9].unpack("H*") + @raw_data[16,1] + @raw_data[18,1] + @raw_data.join[20,6].split(" ") + @raw_data[27,1]
    @outdata << tmpdata
    @outdata = @outdata + @raw_data[14,1] + @raw_data[16,1] + @raw_data.join[18,6].split(" ") + @raw_data[25,1]
puts "#{@outdata}########################################OUTDATA"
    p @outdata
    #return textstr
    return 1
  end
end
