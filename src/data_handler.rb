#!/usr/bin/ruby -Ku
# encoding: utf-8

require_relative 'cloud_db_api'
require_relative 'zigbee'
require_relative 'image_file'
require "logger"

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
    @log = Logger.new("/tmp/data_handler.log")
    @log.level = Logger::DEBUG
    # DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
  end

  attr_accessor :cmd, :id_h

  # クラウドにデバイスを登録してクラウドで扱うセンサIDとセンサアドレスを対応付させる
  # @param [String] addr センサアドレス
  def register_id(addr)
    res = @cloud.post_device(@gw_id, addr)
    @id_h["#{addr}"] = res.values[0][0]["id"]
    @log.debug("MAC-SensorID table :#{@id_h}")
  end

  # ファイルを検索する
  # @return [Boolean] True:ファイル発見 False:ファイル未発見
  # TODO
  def file_search()
    @log.debug("Call file_search method")
    return @file_hdr.search
  end

  # ファイルをクラウドにアップロードする
  # @param [String] path ファイルパス
  # TODO
  def upload
    @log.debug("Call upload method")
    @cloud.upload(@file_hdr.filepath)
  end

  # ローカルに保存されているファイルを削除する
  # TODO
  def delete
    @log.debug("Call delete method")
    @file_hdr.delete()
  end

  # クラウドに温度を通知する
  #
  def store_sensing_data(data)
    @log.debug("Call store_sensing_data method")
    addr = data["addr"]
    @cloud.store_sensing_data(@id_h["#{addr}"], data["temp"])
  end

  def set_sensor_alert(data, min, max)
    @log.debug("Call set_sensor_alert method")
    addr = data["addr"]
    @cloud.set_sensor_alert(@id_h["#{addr}"], data["temp"], min, max)
  end

  def get_monitoring_range(data)
    @log.debug("Call get_monitoring_range method")
    addr = data["addr"]
    res = @cloud.get_monitor_range(id_h["#{addr}"])
    return res
  end

  def get_operation
    @log.debug("Call get_operation method")
    res = @cloud.get_operation(@gw_id)
    return res.values[0]["operation_id"], res.values[0]["value"]
  end

  def set_operation_status(gateway_id, status)
    @log.debug("Call set_operation_status method")
    @cloud.set_operation_status(gateway_id, status)
  end

  # ドア開錠コマンド取得のAPIを実行
  # TODO 引数と返り値の処理
  def get_door_cmd(xxx)
    @log.debug("Call get_door_cmd method")
    res = @cloud.get_door_cmd(xxx)
    return res.values[0]["operation_id"], res.values[0]["value"]
  end

  # TODO Destructorを実装してログアウトしたい
  def logout
    @log.debug("Call logout method")
#    @cloud.logout()
  end

end

