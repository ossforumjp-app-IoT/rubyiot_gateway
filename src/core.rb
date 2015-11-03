#!/usr/bin/ruby

require 'rubygems'
require 'uri'
require 'net/http'
require 'active_record'

#http用
require 'net/http'
require 'uri'

require_relative 'xbeemodule'

require 'httpclient'
require 'digest/sha2'
require 'pry'

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
    #@http = Net::HTTP.new(server, port)

=begin
		#PROXY
		proxy_host = 
		proxy_user = 
		proxy_passwd = 
=end
		#@http = HTTPClient.new(proxy_host)
		@http = HTTPClient.new
		#@http.set_proxy_auth(proxy_user, proxy_passwd)
		@http.set_auth(server, 'aaa', Digest::SHA256.hexdigest('aaa'))
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
     huid_hash = {'hardware_uid' => hardware_uid,
# LSIさん用
#    huid_hash = {'hardware_uid' => '0013a2004066107e',
                 'class_group_code' => '0x00',
                 'class_code' => '0x11',
                 'properties' => { '0x00' => 'sensor',
                                   '0x01' => 'controller'}}
    post_data = huid_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('http://rubyiot.rcloud.jp/api/device', post_data)
  end

  # センサの監視値（上限値・下限値）を登録・更新するメソッド
  #   @param [Integer] センサーID
  #   @param [Integer] 監視値下限値
  #   @param [Integer] 監視値上限値
  #
  # クラウドにアクセスして登録されている監視値（上限値・下限値）を更新します。
  def setMonitorRange(sensor_id, min, max)
    monitor_range = { 'min' => min.to_s, 'max' => max.to_s }
    query_hash = { sensor_id => monitor_range }
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")
    res = @http.post('http://rubyiot.rcloud.jp/api/monitor', post_data)
		puts res
    puts JSON.parse(res.body)
  end

  # センサの監視値（上限値・下限値）を取得するメソッド
  #   @param [Integer] センサーID
  #
  # クラウドにアクセスして監視値（上限値・下限値）を取得します。
  # メソッドの結果としてはハッシュで返します。
  def getMonitorRange(sensor_id)
    query_hash = { 'sensor_id' => sensor_id }
    debug("GET Query Data : #{query_hash.to_query}")
    res = @http.get("http://rubyiot.rcloud.jp/api/monitor?#{query_hash.to_query}")
		puts res
    puts JSON.parse(res.body)
    JSON.parse(res.body)
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
    res=@http.post('http://rubyiot.rcloud.jp/api/sensor_data', post_data)
		puts res
    puts JSON.parse(res.body)
    return res
  end

  # リモート操作指示状態を取得するメソッド
  #   @param [Integer] ゲートウェイID
  def getOperation(gateway_id)
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")
    res = @http.get("http://rubyiot.rcloud.jp/api/operation?#{query_hash.to_query}")
		puts res
    puts JSON.parse(res.body)
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
    res = @http.post('http://rubyiot.rcloud.jp/api/operation_status', post_data)
		puts res
    puts JSON.parse(res.body)
  end

  # センサ監視値設定メソッド
  #   @param [Integer] センサID
  #   @param [Integer] 下限値
  #   @param [Integer] 上限値
=begin #同じ機能のメソッドがある(setMonitorRange)
  def setSensorInfo(sensor_id, min, max)
    monitor_range = { 'min' => min.to_s, 'max' => max.to_s }
    query_hash = { sensor_id => monitor_range }
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('http://rubyiot.rcloud.jp/api/monitor', post_data)
  end
=end

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
    res = @http.post('http://rubyiot.rcloud.jp/api/sensor_alert', post_data)
		puts res
    puts JSON.parse(res.body)
  end

  # センサ情報取得メソッド
  #   @param [Integer] ゲートウェイID
  def getSensor(gateway_id)
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")
    res = @http.get("http://rubyiot.rcloud.jp/api/sensor?#{query_hash.to_query}")
		puts res
    puts JSON.parse(res.body)
    JSON.parse(response.body)
  end

  # コントローラ情報取得メソッド
  #   @param [Integer] ゲートウェイID
  def getController(gateway_id)
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")
    response = @http.get("http://rubyiot.rcloud.jp/api/controller?#{query_hash.to_query}")
    JSON.parse(response.body)
  end

  # デバイス情報設定メソッド
  def postDevice(gateway_id,device_id)
=begin
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
=end
		huid_hash = {
			'gateway_uid' => gateway_id,
			'device_uid' => device_id,
			'class_group_code' => '0x00',
			'class_code' => '0x00',
			'properties' => [
				{
					'class_group_code' => '0x00',
					'class_code' => '0x00',
					'property_code'=>'0x30',
					'type' => 'sensor'
				},
				{
					'class_group_code' => '0x00',
					'class_code' => '0x00',
					'property_code'=>'0x31',
					'type' => 'controller'
				}
			]
		} 
    post_data = huid_hash.to_json
    debug("POST Data : #{post_data}")
    res = @http.post('http://rubyiot.rcloud.jp/api/device', post_data)
    puts "--- 応答 ---"
		puts res
    puts JSON.parse(res.body)
    return JSON.parse(response.body)

  end

  # センサ情報設定メソッド
  #   @param [Integer] センサID
  #   @param [String] センサ名
  def postApiSensor(sensor_id, name)
    aaaa_hash = {'name' => name}
    test_hash = { sensor_id => aaaa_hash }
    post_data = test_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('http://rubyiot.rcloud.jp/api/sensor', post_data)
  end

  # コントローラ情報設定メソッド
  #   @param [Integer] コントローラID
  #   @param [String] コントローラ名
  def postApiController(controller_id, name)
    aaaa_hash = {'name' => name}
    test_hash = { controller_id => aaaa_hash }
    post_data = test_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('http://rubyiot.rcloud.jp/api/controller', post_data)
  end

  # センサ情報設定メソッド
  #   @param [Integer] センサID
  #   @param [Integer] 測定値
  def postApiSensorData(sensor_id, val)
    test_hash = { sensor_id => val }
    post_data = test_hash.to_json
    debug("POST Data : #{post_data}")
    @http.post('http://rubyiot.rcloud.jp/api/sensor_data', post_data)
  end

  # センサ情報取得メソッド
  #   @param [Integer] センサID
  def getSensorData(sensor_id)
    response = @http.get('http://rubyiot.rcloud.jp/api/sensor_data?sensor_id=11&start=2015-01-23+00:00:00&span=5-minutely')
    JSON.parse(response.body)
  end

  def debug(msg)
    #puts "  " + msg
  end

  # ログインメソッド
  def login
    post_hash = { #'username' => @username,
                  'username' => 'aaa',
                  #'password_hash' => Digest::SHA256.hexdigest(@password) }
                  'password_hash' => Digest::SHA256.hexdigest('aaa') }
    post_data = post_hash.to_json
    res = @http.post('http://rubyiot.rcloud.jp/api/login', post_data)
  end

  # ログアウトメソッド
  def logout
    res = @http.get('http://rubyiot.rcloud.jp/api/logout')
  end

  # controllerへの操作指示を登録する
  # @param [Integer] コントローラID
  # @param [Integer] ON/OFF(0/1)
  def setOperation(controller_id, operation)
    post_hash = { controller_id => operation }
    post_data = post_hash.to_json
    res = @http.post('http://rubyiot.rcloud.jp/api/operation', post_data)
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

  def senddata(limit_max,limit_min,sensorctl,addr)

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

    @zigrecv.send_data(data,addr)
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
  def get_temp
    return @zigrecv.get_temp
  end

  # 異常状態取得
  def get_fail_status
    return @zigrecv.get_fail_status
  end

	# get device mac
	def get_addr
		return @zigrecv.get_addr
	end

end

