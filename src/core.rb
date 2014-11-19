#!/usr/bin/ruby

require 'uri'
require 'net/http'
require 'active_record'

#http用
require 'net/http'
require 'uri'

require_relative 'xbeemodule'

# データベースアクセス用のクラス
class LocalDbData < ActiveRecord::Base
end

# ラズベリーパイ内に持つＤＢへのアクセスを実装する
class LocalDb
  # ローカルDBの初期化を行うメソッド
  def initialize
    ActiveRecord::Base.establish_connection(
      'adapter'  => 'sqlite3',
      'database' => 'db/localdb.db'
    )
  end

  # センサ情報設定メソッド
  def setSensorInfo(sensor_id)
    LocalDbData.update(
      :device_property_id => sensor_id,
      :value => sensing_data,
      :measured_at => timestamp
    )
  end

  # センサ情報取得メソッド
  def getSensorInfo(sensor_id)
  end

  # 監視値設定メソッド
  def setMonitorRange(sensor_id)
  end

  # 監視値取得メソッド
  def getMonitorRange(sensor_id)
  end

  # 温度異常イベント登録メソッド
  def setMonitorAlert(sensor_id)
  end

  # 温度異常イベント取得メソッド
  def getMonitorAlert(sensor_id)
  end

  def storeSensingData(sensor_id, timestamp, sensing_data)
#    LocalDbData.create(
#      :device_property_id => sensor_id,
#      :value => sensing_data,
#      :measured_at => timestamp
#    )
  end

  # センサデータ取得メソッド
  def loadSensingData
    LocalDbData.find(:all)
#   LocalDbData.find_all_by_id([1,2])
  end
end

# クラウド上のＤＢアクセスクラス
class CloudDb
  # クラウド上のＤＢアクセスクラスの初期化
  #
  # クラウドにアクセスするための準備を行う。
  #def initialize(server)
  #  @http = Net::HTTP.new(server)
  #end

  # クラウド上のＤＢアクセスクラスの初期化
  #
  # クラウドにポート指定でアクセスするための準備を行う。
  def initialize(server, port)
    @http = Net::HTTP.new(server, port)
  end

  # クラウド上のＤＢアクセスクラスの初期化
  #
  # プロキシ経由でクラウドにアクセスするための準備を行う。
  # (FAE社内アクセス対応)
  #def initialize(server, proxy_host, proxy_port, proxy_user, proxy_passwd)
  #  proxy = Net::HTTP::Proxy(proxy_host, proxy_port, proxy_user, proxy_passwd)
  #  @http = proxy.new(server)
  #end

  # センサ登録・更新メソッド
  #   @param [Integer] センサーID
  #   @param [String]  タイムスタンプ
  #   @param [Integer] センシングデータ
  def setDevice(hardware_uid, class_group_code, class_code, properties)
# 社内評価用
#    huid_hash = {'hardware_uid' => '0013a20040b189bc',
# LSIさん用
    huid_hash = {'hardware_uid' => '0013a2004066107e',
                 'class_group_code' => '0x00',
                 'class_code' => '0x11',
                 'properties' => { '0x00' => 'sensor',
                                   '0x01' => 'controller'}}
    post_data = huid_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('/api/device', post_data)
  end

  # センサの監視値（上限値・下限値）を登録・更新するメソッド
  #   @param [Integer] センサーID
  #   @param [Integer] 監視値下限値
  #   @param [Integer] 監視値上限値
  #
  # クラウドにアクセスして登録されている監視値（上限値・下限値）を更新します。
  def setMonitorRange(sensor_id, min, max)
    monitor_range = { 'min' => min.to_s, 'max' => max.to_s }
    #query_hash = { 'sensor_id' => monitor_range }
    query_hash = { '1' => monitor_range }
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('/api/monitor', post_data)
  end

  # センサの監視値（上限値・下限値）を取得するメソッド
  #   @param [Integer] センサーID
  #
  # クラウドにアクセスして監視値（上限値・下限値）を取得します。
  # メソッドの結果としてはハッシュで返します。
  def getMonitorRange(sensor_id)
    query_hash = { 'sensor_id' => sensor_id }
    debug("GET Query Data : #{query_hash.to_query}")
    response = @http.get("/api/monitor?#{query_hash.to_query}")
    JSON.parse(response.body)
  end

  # センサデータ蓄積メソッド
  #   @param [Integer] センサーID
  #   @param [String]  タイムスタンプ
  #   @param [Integer] センシングデータ
  def storeSensingData(sensor_id, timestamp, sensing_data)
    debug("storeSensingData call")
    query_hash = {sensor_id => sensing_data.to_s}
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('/api/sensor_data', post_data)
  end

  # リモート操作指示状態を取得するメソッド
  #   @param [Integer] ゲートウェイID
  #
  # クラウドにアクセスしてリモート操作指示状態を取得します。
  def getOperation(gateway_id)
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")
    response = @http.get("/api/operation?#{query_hash.to_query}")
    JSON.parse(response.body)
  end

  # 
  def setOperationStatus(gateway_id, status)
    debug("setOperationStatus call")
    query_hash = {gateway_id => status.to_s}
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('/api/operation_status', post_data)
  end

  # センサ情報設定メソッド
  def setSensorInfo()
    monitor_range = { 'min' => min.to_s, 'max' => max.to_s }
    query_hash = { sensor_id => monitor_range }
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('/api/monitor', post_data)
  end

  def setSensorAlert(sensor_id, value, min, max)
    monitor_range = {'value' => value, 'min' => min, 'max' => max}
    s_alert = { sensor_id => monitor_range }
    post_data = s_alert.to_json
    debug("POST Data : #{post_data}")
    @http.post('/api/sensor_alert', post_data)
  end


  def debug(msg)
    puts "  " + msg
  end
end


# エアコン制御クラス
class Airconditioner
  # コンストラクタでアドレスとか指定しておく必要がある

  # ONメソッド

  # OFFメソッド

end

# センサクラス
# XbeeでFM3と接続して温度照度を取得する仕事
class Sensor
  # センシング情報を取ってくるメソッド
  def initialize
    @zigrecv = ZigBeeReceiveFrame.new
  end

  def recvdata
    @zigrecv.recv_data
    #@zigrecv.recv_data_dummy
  end

  def senddata(limit_max,limit_min,sensorctl)

    min_expr = '+'
    max_expr = '+'

    if limit_min < 0 then
      limit_min = limit_min * -1
      min_expr = '-'
    end
    tmpminstr = limit_min.to_s
    tmp_min_x = tmpminstr.split(".")
    if tmp_min_x.length == 1 then
      tmp_min_x.push("0")
    end

    if limit_max < 0 then
      limit_max = limit_max * -1
      max_expr = '-'
    end
    tmpmaxstr = limit_max.to_s
    tmp_max_x = tmpmaxstr.split(".")
    if tmp_max_x.length == 1 then
      tmp_max_x.push("0")
    end

    data = sprintf("%d,%d,%c%03d.%s,%c%03d.%s", 0, sensorctl, max_expr, limit_max, tmp_max_x[1], min_expr, limit_min, tmp_min_x[1])

    puts "data = #{data}"

    @zigrecv.send_data(data)
  end


  # 装置状態
  def get_device_status
    return @zigrecv.get_device_status
  end

  # fan状態
  def get_fan_status
    return @zigrecv.get_fan_status
  end

  # 温度
  def sense
    return @zigrecv.get_temp
  end

  # 異常状態
  def get_fail_status
    return @zigrecv.get_fail_status
  end

end


#cloudDb = CloudDb.new()
#cloudDb.storeSensingData('id','time','data') 

