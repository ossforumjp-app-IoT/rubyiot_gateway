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

# Raspberry Pi 内に持つ　Database　へのアクセス実装
# @attr[Net::HTTP] http NET::HTTPのインスタンス
class LocalDb
  # LocalDbの初期化
  #   @param [String] sever
  #   @param [String] port
  def initialize(server, port)
    @http = Net::HTTP.new(server, port)
  end

  # sensorの監視値（上限値・下限値）を取得する
  #   @param [Integer] sensor_id センサーID
  #   @return [Hash] {"min": "下限値", "max": "上限値"}
  def getMonitorRange(sensor_id)
    query_hash = { 'sensor_id' => sensor_id }
    debug("GET Query Data : #{query_hash.to_query}")
    response = @http.get("/api/monitor?#{query_hash.to_query}")
    JSON.parse(response.body)
  end

  # ローカルDBにセンサーの測定データを登録
  # @todo timestamp は利用されないので、後に削除
  #   @param [Integer] sensor_id    センサーID
  #   @param [String]  timestamp    タイムスタンプ
  #   @param [Integer] sensing_data センサの測定値
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
  #   @param [Integer]　gateway_id ゲートウェイID
  #   @return [Hash] センサの情報
  #   @see https://github.com/ossforumjp-app-IoT/rubyiot_server に参考
  def getSensor(gateway_id)
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")
    response = @http.get("/api/sensor?#{query_hash.to_query}")
    JSON.parse(response.body)
  end

  # messageを表示
  def debug(msg)
    puts "  " + msg
  end
end

# クラウド上のDatabaseアクセスクラス
# @attr [HTTPClient] http HTTPClientのインスタンス
# @todo Net:Http　か HTTPClient か　
class CloudDb
  # クラウド上のＤＢアクセスクラスの初期化
  #   @param [String] sever server_url
  #   @param [String] port  serverのポート番号
  def initialize(server, port)
    #@http = Net::HTTP.new(server, port)

=begin
		#PROXYがある場合、以下のように　http　を初期化
		proxy_host =　       http://myproxy:8080
		proxy_user =    user
		proxy_passwd =  passwd

		@http = HTTPClient.new(proxy_host)
		@http.set_proxy_auth(proxy_user, proxy_passwd)
    @http.set_auth(server, 'aaa', Digest::SHA256.hexdigest('aaa'))
=end

    @http = HTTPClient.new
    @http.set_auth(server, 'aaa', Digest::SHA256.hexdigest('aaa'))

=begin
  # Net::HTTP、以下のように　http　を初期化
  #
  # プロキシ経由でクラウドにアクセスするための準備を行う。
  # (FAE社内アクセス対応)
  #def initialize(server, proxy_host, proxy_port, proxy_user, proxy_passwd)
  #  proxy = Net::HTTP::Proxy(proxy_host, proxy_port, proxy_user, proxy_passwd)
  #  @http = proxy.new(server)
  #end
=end

  end

  # センサの監視値（上限値・下限値）を登録・更新するメソッド
  #   @param [Integer] sensor_id  センサーID
  #   @param [Integer] min        監視値下限値
  #   @param [Integer] max        監視値上限値
  def setMonitorRange(sensor_id, min, max)
    monitor_range = { 'min' => min.to_s, 'max' => max.to_s }
    query_hash = { sensor_id => monitor_range }
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")
    res = @http.post('http://rubyiot.rcloud.jp/api/monitor', post_data)
    #		puts res
    puts JSON.parse(res.body)
  end

  # センサの監視値（上限値・下限値）を取得するメソッド
  #   @param [Integer] sensor_id センサーID
  #   @return [Hash]   monitor range in hash form  { "xxx": { "min": "下限値", "max": "上限値" } } (xxx: sensor_id)
  def getMonitorRange(sensor_id)
    query_hash = { 'sensor_id' => sensor_id }
    debug("GET Query Data : #{query_hash.to_query}")
    res = @http.get("http://rubyiot.rcloud.jp/api/monitor?#{query_hash.to_query}")
    JSON.parse(res.body)
  end

  # センサーの測定データを登録
  #   @param [Integer]  sensor_id     センサーID
  #   @param [String]   timestamp     タイムスタンプ
  #   @param [Integer]  sensing_data  センシングデータ
  def storeSensingData(sensor_id, timestamp, sensing_data)
    debug("storeSensingData call")
    query_hash = {sensor_id => sensing_data.to_s}
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")
    res = @http.post('http://rubyiot.rcloud.jp/api/sensor_data', post_data)
  end

  # リモート操作指示状態を取得するメソッド
  #   @param [Integer] gateway_id ゲートウェイID
  def getOperation(gateway_id)
    #  def getOperation(hardware_uid)
    #    query_hash = { 'hardware_uid' => hardware_uid }
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")
    res = @http.get("http://rubyiot.rcloud.jp/api/operation?#{query_hash.to_query}")
    JSON.parse(res.body)
  end

  #  controllerへの操作指示を登録
  #   @param [Integer] gateway_id  ゲートウェイID
  #   @param [Integer] status      扇風機の状態
  def setOperationStatus(gateway_id, status)
    debug("setOperationStatus call")
    query_hash = {gateway_id => status.to_s}
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")
    res = @http.post('http://rubyiot.rcloud.jp/api/operation_status', post_data)
    #return JSON.parse(res.body)
  end

  # センサーの測定データを登録
  #   @param [Integer] sensor_id センサID
  #   @param [Integer] value     測定値
  #   @param [Integer] min      下限値
  #   @param [Integer] max      上限値
  def setSensorAlert(sensor_id, value, min, max)
    monitor_range = {'value' => value, 'min' => min, 'max' => max}
    s_alert = { sensor_id => monitor_range }
    post_data = s_alert.to_json
    debug("POST Data : #{post_data}")
    res = @http.post('http://rubyiot.rcloud.jp/api/sensor_alert', post_data)
  end

  # 指定したgatewayの配下にあるsensorのリストを取得
  #   @param [String] gateway_id ゲートウェイID
  #   @return [Hash] a list of sensors information
  #   @see https://github.com/ossforumjp-app-IoT/rubyiot_server
  def getSensor(gateway_id)
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")
    response = @http.get("http://rubyiot.rcloud.jp/api/sensor?#{query_hash.to_query}")
    JSON.parse(response.body)
  end

  # sensorやcontrollerが接続されたdeviceを、登録・更新
  # @param [String] gateway_id  gatewayのhardware_uid(Seriarl、MACなど) Ex: 0013a2004066107e
  # @param [String] device_id   deviceのhardware_uid(Seriarl、MACなど)  Ex: 0013a2004066107e
  # @return [Hash] @see https://github.com/ossforumjp-app-IoT/rubyiot_server for fulllist
  def postDevice(gateway_id,device_id)

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
    puts JSON.parse(res.body)
    return JSON.parse(res.body)

  end

  def debug(msg)
    puts "  " + msg
  end

  # ログインメソッド
  def login

    # username/password for http://rubyiot.rcloud.jp/api/login
    username = 'aaa'
    password = 'aaa'

    post_hash = {
      'username' => username,
      'password_hash' => Digest::SHA256.hexdigest(password)
    }

    post_data = post_hash.to_json
    res = @http.post('http://rubyiot.rcloud.jp/api/login', post_data)

  end

  # ログアウトメソッド
  def logout
    res = @http.get('http://rubyiot.rcloud.jp/api/logout')
  end

  # controllerへの操作指示を登録
  # @param [Integer] controller_id  コントローラID
  # @param [Integer] operation      ON/OFF(0/1)
  def setOperation(controller_id, operation)
    post_hash = { controller_id => operation }
    post_data = post_hash.to_json
    res = @http.post('http://rubyiot.rcloud.jp/api/operation', post_data)
  end

end

# センサクラス
# XbeeでFM3と接続して温度照度を取得する仕事
# @attr [ZigBeeReceiveFrame] zigrecv ZigBeeReceiveFrame instance
class Sensor
  # センシング情報を取ってくるメソッド
  def initialize
    @zigrecv = ZigBeeReceiveFrame.new
  end

  # Serial経由でXbeeのデータ取得
  def recvdata
    @zigrecv.recv_data
  end

  # Serial経由でXbeeにデータを送る
  #   @param [Numeric] limit_max    上限値
  #   @param [Numeric] limit_min    下限値
  #   @param [Numeric] sensorctl    ????
  #   @param [Numeric] addr         Xbeeのmac address
  #   @todo データ送るかデータを設定することか？
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

    puts "data = #{data} #{addr}"

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

## CloudDbの利用しない methods
## @todo 後で削除
#class CloudDbExtend < CloudDb
#  # センサ情報設定メソッド
#  #   @param [Integer] センサID
#  #   @param [String] センサ名
#  def postApiSensor(sensor_id, name)
#    aaaa_hash = {'name' => name}
#    test_hash = { sensor_id => aaaa_hash }
#    post_data = test_hash.to_json
#    debug("POST Data : #{post_data}")
#    @http.post('http://rubyiot.rcloud.jp/api/sensor', post_data)
#  end
#
#  # コントローラ情報設定メソッド
#  #   @param [Integer] コントローラID
#  #   @param [String] コントローラ名
#  def postApiController(controller_id, name)
#    aaaa_hash = {'name' => name}
#    test_hash = { controller_id => aaaa_hash }
#    post_data = test_hash.to_json
#    debug("POST Data : #{post_data}")
#    @http.post('http://rubyiot.rcloud.jp/api/controller', post_data)
#  end
#
#  # センサ情報取得メソッド
#  #   @param [Integer] センサID
#  def getSensorData(sensor_id)
#    response = @http.get('http://rubyiot.rcloud.jp/api/sensor_data?sensor_id=11&start=2015-01-23+00:00:00&span=5-minutely')
#    JSON.parse(response.body)
#  end
#
#  # コントローラ情報取得メソッド
#  #   @param [Integer] ゲートウェイID
#  def getController(gateway_id)
#    query_hash = { 'gateway_id' => gateway_id }
#    debug("GET Query Data : #{query_hash.to_query}")
#    response = @http.get("http://rubyiot.rcloud.jp/api/controller?#{query_hash.to_query}")
#    JSON.parse(response.body)
#  end
#
#  # センサ情報設定メソッド
#  #   @param [Integer] センサID
#  #   @param [Integer] 測定値
#  def postApiSensorData(sensor_id, val)
#    test_hash = { sensor_id => val }
#    post_data = test_hash.to_json
#    debug("POST Data : #{post_data}")
#    @http.post('http://rubyiot.rcloud.jp/api/sensor_data', post_data)
#  end
#
#  # センサ登録・更新メソッド
#  #   @param [Integer] センサーID
#  #   @param [String]  タイムスタンプ
#  #   @param [Integer] センシングデータ
#  def setDevice(hardware_uid, class_group_code, class_code, properties)
#    # 社内評価用
#    #    huid_hash = {'hardware_uid' => '0013a20040b189bc',
#    huid_hash = {'hardware_uid' => hardware_uid,
#      # LSIさん用
#      #    huid_hash = {'hardware_uid' => '0013a2004066107e',
#      'class_group_code' => '0x00',
#      'class_code' => '0x11',
#      'properties' => { '0x00' => 'sensor',
#      '0x01' => 'controller'}}
#    post_data = huid_hash.to_json
#    debug("POST Data : #{post_data}")
#    @http.post('http://rubyiot.rcloud.jp/api/device', post_data)
#  end
#
#end
