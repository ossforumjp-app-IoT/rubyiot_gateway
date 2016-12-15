#!/usr/bin/ruby -Ku

require_relative 'cloud_db_api'
require_relative 'zigbee'


# GWのデータを扱うクラス
class DataHandler
  
  # @param [Integer] @gw_id クラウドで管理するGWのID
  # @param [Queue] @data クラウドから受信したデータを格納
  # @param [Hash] @id_h "センサID"："センサアドレス"
  def initialize(id)
    @gw_id = id
    @cloud = CloudDatabaseAPI.new
    @cloud.get_sensor(@gw_id)
    @cloud.login() #XXX 何故ログインが後？

    @data = Queue.new
    @id_h = Hash.new
    @min = 30.0
    @max = 10.0
  end

  # クラウドにデバイスを登録してクラウドで扱うセンサIDとセンサアドレスを対応付させる
  # @param [String] addr センサアドレス
  def register_id(addr)
    res = @cloud.post_device(@gw_id, addr)
    @id_h["#{addr}"] = res.values[0][0]["id"]
  end

  # ファイルをクラウドにアップロードするクラス
  # @param [String] path ファイルパス
  def upload(path) 
    @cloud.upload(path)
  end

  def store_sensing_data(data)
    addr = data["addr"]
    t = Thread.new {
      unless @id_h.has_key?(addr) then
        register_id(addr)
      end
      res = @cloud.sotre_sensing_data(id_h["#{addr}"], data["temp"])
    }
  end

  def notify_alert(data)
    @cloud.notify_alert(id_h["#{addr}"], data["temp"], @min, @max)
  end

  def get_monitoring_range()
  
  end

  def get_operation
  
  end

  # TODO Destructorを実装したい
  # それまでの代わりのメソッド
  def logout
    @cloud.logout()
  end

end


# Debug
if $0 == __FILE__ then

  d_hdr = DataHandler.new
  
end

