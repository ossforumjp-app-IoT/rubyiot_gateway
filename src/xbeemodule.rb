#!/usr/bin/ruby

# XBeeモジュール用のフレームをRAWデータで取り扱うクラス
#
# XBeeモジュールのフレーム構造
# +--+----+--------+--+
# |7E|    |        |  |
# +--+----+--------+--+
#  |  |    |        |
#  |  |    |        +--- チェックサム(データ部を足し合わせた値の下位8Byteを反転した値
#  |  |    +------------ データ部
#  |  +----------------- データ長(データ部のByte長)
#  +-------------------- 開始コード(7E固定)
#
# @todo @frame_bin_dataがnilの場合の処理全然書いてない。
#       対応案1: 初期化で引数を与えるようにしてnilを許さないようにするか
#       対応案2: 各メソッドで@frame_bin_dataがnilの場合はnilを戻すようにする

require 'serialport'

class XBeeModuleRawFrame
  :public
  def initialize()
    @frame_bin_data = nil
  end

  # フレームのRAWデータを16進文字列で設定するメソッド
  def data_hex=(hex)
    no_space_hex = [hex.tr(" ", "")]
    @frame_bin_data = no_space_hex.pack("H*")
  end

  # フレームのRAWデータのバイナリを設定するメソッド
  def data=(bin)
    @frame_bin_data = bin
  end

  # フレームのRAWデータのデータ長を取得するメソッド
  def length
    @frame_bin_data.length
  end

  # フレームのRAWデータのデータ長を16進文字列で取得するメソッド
  def length_hex
    sprintf("%04x", length)
  end

  # フレームのRAWデータのチェックサムを取得するメソッド
  def sum
    ~(@frame_bin_data.sum) & 0xFF
  end

  # フレームのRAWデータのチェックサムを16進文字列で取得するメソッド
  def sum_hex
    sprintf("%02x", sum)
  end

  # フレームからコマンドIDを16進文字列で設定するメソッド
  def command_id_hex=(hex)
    @frame_bin_data[0] = [hex].pack("H*")
  end

  # フレームからコマンドIDを16進文字列を取得するメソッド
  def command_id_hex
    @frame_bin_data[0].unpack("H*")
  end

  # フレーム全体をバイナリを取得するメソッド
  def frame
    # データが設定されていない状態の場合はnilを返す
    return nil if ( nil == @frame_bin_data )

    # フレームに開始コードを追加
    binframe =  ["7E"].pack("H*")

    # フレームにデータ長を追加
    binframe += [length_hex].pack("H*")

    # フレームにデータを追加
    binframe += @frame_bin_data

    # フレームにチェックサムを追加
    binframe += [sum_hex].pack("H*")
  end

  # フレーム全体を16進文字列で取得するメソッド
  def frame_hex
    frame.unpack("H*")
  end
end


# XBeeモジュール用のZigBee Transmit Requestフレームを取り扱うクラス
class ZigBeeTransmitRequestFrame < XBeeModuleRawFrame
  # フレームデータをセットするメソッド
  def data=(frame_id_hex, addr64_hex, addr16_hex, broadcast_range_radius_hex, send_option_hex, rfdata)
  end

  # フレームIDを16進数文字列で取得するメソッド
  def frame_id_hex
  end

  # フレームIDを16進数文字列で設定するメソッド
  def frame_id_hex(hex)
  end

  # 64bit 宛先アドレスを16進数文字列で取得するメソッド
  def addr64_hex
  end

  # 64bit 宛先アドレスを16進数文字列で設定するメソッド
  def addr64_hex=(hex)
  end

  # 16bit 宛先アドレスを16進数文字列で取得するメソッド
  def addr16_hex
  end

  # 16bit 宛先アドレスを16進数文字列で設定するメソッド
  def addr16_hex=(hex)
  end

  # ブロードキャスト半径を16進数文字列で取得するメソッド
  def broadcast_range_radius_hex
  end

  # ブロードキャスト半径を16進数文字列で設定するメソッド
  def broadcast_range_radius_hex=(hex)
  end

  # 送信オプションを16進数文字列で取得するメソッド
  def send_option_hex
  end

  # 送信オプションを16進数文字列で設定するメソッド
  def send_option_hex=(hex)
  end

  # RF-Dataを16進数文字列で取得するメソッド
  def rfdata_hex
  end

  # RF-Dataを16進数文字列で設定するメソッド
  def rfdata_hex=(hex)
  end

  # RF-Dataを無変換で取得するメソッド
  def rfdata
  end
  
  # RF-Dataを無変換で設定するメソッド
  def rfdata=(bin)
  end
end

#frame = XBeeModuleRawFrame.new
#frame.data_hex="90 00 13 A2 00 40 4B 88 42 00 00 01 54 78 44 61 74 61 30 41"
#puts frame.sum_hex
#puts frame.frame_hex
#
#puts frame.command_id_hex
#
#frame.command_id_hex = "91"
#puts frame.frame_hex

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
    @xbeedstaddr   = "00 13 a2 00 40 b1 89 bc"
    # 以下社内Xbeemodule
    #@xbeedstaddr   = "00 13 a2 00 40 66 10 7e"
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
    @count = 0
    length = 100
    loop do
      # 文字を1byte読み込み
      @raw_data[@count] = @sp.read(1)
#p @raw_data[@count]
      if @count == 0 then
        if @raw_data[@count] != '~' then
           next
        end
      end

      if @count == 2 then
        length_str = @raw_data[1,2]
        tmp2 = length_str.join
        tmp1 = tmp2.unpack("n*")
        puts "length = #{tmp1}"
        length = tmp1[0]
        length = length + 2
        p "length = #{length}"
        # データ長は26固定 length の 2を追加
        if length != 28 then
          puts "data length error"
          @count = 0
          next
        end
      end

      # 

      @count = @count+1
      if @count > 2 then
        if @count > length then
          # addressチェックを入れたいが。。。
          # 今回はパス
          chknum = @raw_data[14,1]
          if chknum != ["3"] then
            puts "sensor error st= #{chknum}"
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

#test = ZigBeeReceiveFrame.new
#
#loop do
#  puts "start"
#  test.recv_data
#  recvdata = test.get_data
#  fanstatus = test.get_fan_status
#  temp = test.get_temp
#  status = test.get_status
#  puts "recvdata = #{recvdata}"
#  puts "fanstatus = #{fanstatus}, temp=#{temp} , status=#{status}"
#  puts temp.to_f
#  puts "end"
#end

 

