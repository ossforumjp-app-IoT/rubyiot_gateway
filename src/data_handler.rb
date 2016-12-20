#!/usr/bin/ruby -Ku

require_relative 'cloud_db_api'
require_relative 'zigbee'
require_relative 'image_file'


# GWのデータを扱うクラス
class DataHandler

  # @param [Integer] @gw_id クラウドで管理するGWのID
  # @param [Queue] @cmd クラウドから受信したコマンドを格納
  # @param [Hash] @id_h "センサID"："センサアドレス"
  def initialize(gw_id)
    @gw_id = gw_id
    @cloud = CloudDatabaseAPI.new
    #@cloud.get_sensor(@gw_id)
    #@cloud.login() #XXX 何故ログインが後？

    @file_hdr = ImageFile.new

    @cmd = Queue.new
    @id_h = Hash.new
  end

  attr_accessor :id_h, :data

  # クラウドにデバイスを登録してクラウドで扱うセンサIDとセンサアドレスを対応付させる
  # @param [String] addr センサアドレス


  def register_id(addr)
    res = @cloud.post_device(@gw_id, addr)
    @id_h["#{addr}"] = res.values[0][0]["id"]
  end

  # ファイルを検索する
  # @return [Boolean] True:ファイル発見 False:ファイル未発見
  # TODO
  def file_search()
    return @file_hdr.search
  end

  # ファイルをクラウドにアップロードする
  # @param [String] path ファイルパス
  # TODO
  def upload
    if @file_hdr.search
      @cloud.upload(@file_hdr.filepath)
    else
      p @file_hdr.filepath + "が存在しません"
    end
  end

  # ローカルに保存されているファイルを削除する
  # TODO
  def delete
    @file_hdr.delete()
  end

  # クラウドに温度を通知する
  #
  def store_sensing_data(data)
    addr = data["addr"]
    @cloud.store_sensing_data(@id_h["#{addr}"], data["temp"])
  end

  # TODO : cloud_db_apiのnotify_alertを実装
  def notify_alert(data, min, max)
    addr = data["addr"]
    @cloud.notify_alert(@id_h["#{addr}"], data["temp"], min, max)
  end

  def get_monitoring_range(data)
    addr = data["addr"]
    res = @cloud.get_monitor_range(id_h["#{addr}"])
    return res
  end

  def get_operation
    res = @cloud.get_operation(@gw_id)

    return res.values[0]["operation_id"], res.values[0]["value"]
  end

  def set_operation_status(gateway_id, status)
    @cloud.set_operation_status(gateway_id, status)
  end

  # ドア開錠コマンド取得のAPIを実行
  # TODO 引数と返り値の処理
  def get_door_cmd(xxx)
    res = @cloud.get_door_cmd(xxx)
    return xxx
  end

  # TODO Destructorを実装してログアウトしたい
  def logout
    @cloud.logout()
  end

end

# TODO テスト終了に以下の行を削除
# Debug
if $0 == __FILE__ then

  d_hdr = DataHandler.new(1)

  # Testing parameters
  data = {"addr" => "00b0b0b0b0b0",
          "temp" => "21"}
  min = 20
  max = 40

  gateway_id = 1111
  status    = "status"

  addr =  "00b0b0b0b0b0"

  puts "==========================================="
  p d_hdr.get_monitoring_range(data)

  puts "==========================================="
  p d_hdr.get_operation()

#  puts "==========================================="
#  d_hdr.notify_alert(data,min,max)

  puts "==========================================="
  p d_hdr.register_id(addr);

  puts "==========================================="
  p d_hdr.set_operation_status(gateway_id, status)

  puts "==========================================="
  p d_hdr.store_sensing_data(data)




end

