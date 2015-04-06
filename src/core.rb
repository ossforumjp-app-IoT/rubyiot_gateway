#!/usr/bin/ruby

require 'rubygems'
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
  def initialize(server, port)
    @http = Net::HTTP.new(server, port)
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

  # ローカルDBへのセンサデータ蓄積メソッド
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

  # センサデータ取得メソッド
  def loadSensingData
    LocalDbData.find(:all)
  end

  # センサ情報取得メソッド
  #   @param [Integer] ゲートウェイID
  def getSensor(gateway_id)
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")
    response = @http.get("/api/sensor?#{query_hash.to_query}")
    JSON.parse(response.body)
  end

  def debug(msg)
    puts "  " + msg
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
  def getOperation(gateway_id)
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")
    response = @http.get("/api/operation?#{query_hash.to_query}")
    JSON.parse(response.body)
  end

  # 操作状態設定メソッド
  #   @param [Integer] ゲートウェイID
  #   @param [Integer] 状態
  def setOperationStatus(gateway_id, status)
    debug("setOperationStatus call")
    query_hash = {gateway_id => status.to_s}
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('/api/operation_status', post_data)
  end

  # センサ監視値設定メソッド
  #   @param [Integer] センサID
  #   @param [Integer] 下限値
  #   @param [Integer] 上限値
  def setSensorInfo(sensor_id, min, max)
    monitor_range = { 'min' => min.to_s, 'max' => max.to_s }
    query_hash = { sensor_id => monitor_range }
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('/api/monitor', post_data)
  end

  # センサalert設定メソッド
  #   @param [Integer] センサID
  #   @param [Integer] 測定値
  #   @param [Integer] 下限値
  #   @param [Integer] 上限値
  def setSensorAlert(sensor_id, value, min, max)
    monitor_range = {'value' => value, 'min' => min, 'max' => max}
    s_alert = { sensor_id => monitor_range }
    post_data = s_alert.to_json
    debug("POST Data : #{post_data}")
    @http.post('/api/sensor_alert', post_data)
  end

  # センサ情報取得メソッド
  #   @param [Integer] ゲートウェイID
  def getSensor(gateway_id)
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")
    response = @http.get("/api/sensor?#{query_hash.to_query}")
    #response = @http.get("/api/sensor?gateway_id=1")
    JSON.parse(response.body)
  end

  # コントローラ情報取得メソッド
  #   @param [Integer] ゲートウェイID
  def getController(gateway_id)
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")
    response = @http.get("/api/controller?#{query_hash.to_query}")
    JSON.parse(response.body)
  end

  # デバイス情報設定メソッド
  def postDevice
#    huid_hash = {'hardware_uid' => '0013a2004066107e',
#                 		'class_group_code' => '0x00',
#		                 'class_code' => '0x11',
#                 'properties' => [{ 
#				   '0x00' => 'sensor',
#                                   '0x01' => 'controller',
#				   'type' => 'sensor'},
#				   {'0x02' => 'sensor',
#				   '0x03' => 'controller',
#				   'type' => 'controller'}]}

    huid_hash = {'hardware_uid' => '0013a2004066cccc',
		 'class_group_code' => '0x00',
		 'class_code' => '0x00',
                 'properties' => [
				{ 
		                'class_group_code' => '0x00',
		                'class_code' => '0x00',
				'property_code'=>'0x30',
				   'type' => 'sensor'},
				{ 
		                'class_group_code' => '0x00',
		                'class_code' => '0x00',
				'property_code'=>'0x31',
				   'type' => 'controller'}
				   ]}
    post_data = huid_hash.to_json
    debug("POST Data : #{post_data}")
    response = @http.post('/api/device', post_data)
    puts "--- 応答 ---"
    puts response.body
    #JSON.parse(response.body)
  end

  # センサ情報設定メソッド
  #   @param [Integer] センサID
  #   @param [String] センサ名
  def postApiSensor(sensor_id, name)
    aaaa_hash = {'name' => name}
    test_hash = { sensor_id => aaaa_hash }
    post_data = test_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('/api/sensor', post_data)
  end

  # コントローラ情報設定メソッド
  #   @param [Integer] コントローラID
  #   @param [String] コントローラ名
  def postApiController(controller_id, name)
    aaaa_hash = {'name' => name}
    test_hash = { controller_id => aaaa_hash }
    post_data = test_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('/api/controller', post_data)
  end

  # センサ情報設定メソッド
  #   @param [Integer] センサID
  #   @param [Integer] 測定値
  def postApiSensorData(sensor_id, val)
    test_hash = { sensor_id => val }
    post_data = test_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('/api/sensor_data', post_data)
  end

  # センサ情報取得メソッド
  #   @param [Integer] センサID
  def getSensorData(sensor_id)
    response = @http.get('/api/sensor_data?sensor_id=11&start=2015-01-23+00:00:00&span=5-minutely')
    JSON.parse(response.body)
  end

  def debug(msg)
    puts "  " + msg
  end
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


  # 装置状態取得
  def get_device_status
    return @zigrecv.get_device_status
  end

  # fan状態取得
  def get_fan_status
    return @zigrecv.get_fan_status
  end

  # 温度情報取得
  def sense
    return @zigrecv.get_temp
  end

  # 異常状態取得
  def get_fail_status
    return @zigrecv.get_fail_status
  end

end

