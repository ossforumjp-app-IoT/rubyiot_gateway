#!/usr/bin/ruby

require 'rubygems'
require 'uri'
require 'net/http'
require 'active_record'
require 'active_support/core_ext'

require 'httpclient'
require 'digest/sha2'
require 'pry'
require 'json'


# クラウド上のDatabaseアクセスクラス
class CloudDatabaseAPI
  # クラウド上のＤＢアクセスクラスの初期化
  #   @param [String] sever server_url
  #   @param [String] port  serverのポート番号
  def initialize
    server = "http://rubyiot.rcloud.jp"
    @mount_point = "http://rubyiot.rcloud.jp"
    @PORT = 80
    @PORT.freeze
    @USER = "pi"
    @PASS = "raspberry"

    # @note tmp variable
    proxy_host=""
    @http = HTTPClient.new(proxy_host)
    #@http.set_proxy_auth(proxy_user, proxy_passwd)
    @http.set_auth(server, @USER, Digest::SHA256.hexdigest(@PASS))

  end

=begin
#PROXYがある場合、以下のように　http　を初期化
proxy_host =　       http://myproxy:8080
proxy_user =    user
proxy_passwd =  passwd

@http = HTTPClient.new(proxy_host)
@http.set_proxy_auth(proxy_user, proxy_passwd)
@http.set_auth(server, 'raspberrypi', Digest::SHA256.hexdigest('raspberrypi'))
=end


  # センサの監視値（上限値・下限値）を登録・更新するメソッド
  #   @param [Integer] sensor_id  センサーID
  #   @param [Integer] min        監視値下限値
  #   @param [Integer] max        監視値上限値
  def set_monitor_range(sensor_id, min, max)
    monitor_range = { 'min' => min.to_s, 'max' => max.to_s }
    query_hash = { sensor_id => monitor_range }
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")

#    res = @http.post(@mount_point + "/api/monitor", post_data)
#    return JSON.parse(res.body)

    return { "xxx" => { "min" =>  "下限値", "max" => "上限値" } }
  end

  # センサの監視値（上限値・下限値）を取得するメソッド
  #   @param [Integer] sensor_id センサーID
  #   @return [Hash]   monitor range in hash form  { "xxx": { "min": "下限値", "max": "上限値" } } (xxx: sensor_id)
  def get_monitor_range(sensor_id)
    query_hash = { 'sensor_id' => sensor_id }
    debug("GET Query Data : #{query_hash.to_query}")

#    res = @http.get(@mount_point + "/api/monitor?#{query_hash.to_query}")
#    return JSON.parse(res.body)

    return { "min" => "下限値", "max" => "上限値" }
  end

  # センサーの測定データを登録
  #   @param [Integer]  sensor_id     センサーID
  #   @param [Integer]  sensing_data  センシングデータ
  def store_sensing_data(sensor_id, sensing_data)
    debug("storeSensingData call")
    query_hash = {sensor_id => sensing_data.to_s}
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")

#    res = @http.post(@mount_point + "/api/sensor_data", post_data)
#    return JSON.parse(res.body)

    return { "xxx" => "測定値" }
  end

  # リモート操作指示状態を取得するメソッド
  #   @param [Integer] gateway_id ゲートウェイID
  def get_operation(gateway_id)
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")

#    res = @http.get(@mount_point + "/api/operation?#{query_hash.to_query}")
#    return JSON.parse(res.body)

    return { "xxx" => { "operation_id" => "yyy", "value"  => "操作値" } }
  end

  #  controllerへの操作指示を登録
  #   @param [Integer] gateway_id  ゲートウェイID
  #   @param [Integer] status      扇風機の状態
  def set_operation_status(gateway_id, status)
    debug("setOperationStatus call")
    query_hash = {gateway_id => status.to_s}
    post_data = query_hash.to_json
    debug("POST Data : #{post_data}")

#    res = @http.post(@mount_point + "/api/operation_status", post_data)
#    return JSON.parse(res.body)

    return { "xxx" => "実行結果" }
  end

  # センサーの測定データを登録
  #   @param [Integer] sensor_id センサID
  #   @param [Integer] value     測定値
  #   @param [Integer] min      下限値
  #   @param [Integer] max      上限値
  def set_sensor_alert(sensor_id, value, min, max)
    monitor_range = {'value' => value, 'min' => min, 'max' => max}
    s_alert = { sensor_id => monitor_range }
    post_data = s_alert.to_json
    debug("POST Data : #{post_data}")

#    res = @http.post(@mount_point + "/api/sensor_alert", post_data)
#    return JSON.parse(res.body)

    return { "alert" => "< 0:無 | 1:有 >", "value" => "測定値","datetime" => "測定時刻", "min" => "下限値", "max" => "上限値" }
  end

  # 指定したgatewayの配下にあるsensorのリストを取得
  #   @param [String] gateway_id ゲートウェイID
  #   @return [Hash] a list of sensors information
  #   @see https://github.com/ossforumjp-app-IoT/rubyiot_server
  def get_sensor(gateway_id)
    query_hash = { 'gateway_id' => gateway_id }
    debug("GET Query Data : #{query_hash.to_query}")

#    response = @http.get(@mount_point + "/api/sensor?#{query_hash.to_query}")
#    return JSON.parse(response.body)

    return { "xxx" => { "name" => "センサーの任意の名前" } }
  end

  # sensorやcontrollerが接続されたdeviceを、登録・更新
  # @param [String] gateway_id  gatewayのhardware_uid(Seriarl、MACなど) Ex: 0013a2004066107e
  # @param [String] device_id   deviceのhardware_uid(Seriarl、MACなど)  Ex: 0013a2004066107e
  # @return [Hash] @see https://github.com/ossforumjp-app-IoT/rubyiot_server for fulllist
  def post_device(gateway_id, device_id)

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

#    res = @http.post(@mount_point + "/api/device", post_data)
#    return JSON.parse(res.body)

    #    puts "--- 応答 ---"
#    puts JSON.parse(res.body)

	return {"2"=>[{"id"=>"60", "class_group_code"=>"0x00", "class_code"=>"0x00", "property_code"=>"0x30"}, {"id"=>"61", "class_group_code"=>"0x00", "class_code"=>"0x00", "property_code"=>"0x31"}]}

  end

  def debug(msg)
    puts "  " + msg
  end

  # ログインメソッド
  def login
    post_hash = {
      'username' => @USER,
      'password_hash' => Digest::SHA256.hexdigest(@PASS)
    }
    post_data = post_hash.to_json
    res = @http.post(@mount_point + "/api/login", post_data)

  end

  # ログアウトメソッド
  def logout
    res = @http.get(@mount_point + "/api/logout")

    return { "username" => "xxx",
    "password_hash" => "SHA-256でハッシュしたパスワード" }
  end

  # controllerへの操作指示を登録
  # @param [Integer] controller_id  コントローラID
  # @param [Integer] operation      ON/OFF(0/1)
  def set_operation(controller_id, operation)
    post_hash = { controller_id => operation }
    post_data = post_hash.to_json

#    res = @http.post(@mount_point + "/api/operation", post_data)
#    return JSON.parse(response.body)

    return { "xxx" => "操作値" }
  end

  # クラウドにファイルをアップロードするメソッド
  # @param [String] filepath ファイルのパス
  # TODO メソッド名とboundaryは仮決め。
  # 動作未確認
  def upload(filepath)
    boundary = "-------------------------------"
    open(filepath) do |file|
      post_data = {"XXX"=>file}
      @http.post_content(@mount_point + "/api/XXX", post_data,
                         "content-type" => "multipart/form-data,
                         boundary=#{boundary}")
    end

  end

  # ドアの開錠コマンドを取得
  # TODO メソッド名は仮決め
  # 動作未確認
  def get_door_cmd
    res = @http.get(@mount_point + "api/XXX")
    return JSON.parse(res.body)
  end

  # Dummy class to notify alert
  def notify_alert(gw_id, temp, min, max)
    post_data =  { gw_id =>
                  { "value" => temp,
                    "min" => min,
                    "max" => max } }

#    res = @http.get(@mount_point + "/api/sensor_alert" + post_data.to_json)
    res =   { "xxx" => { "value" => "測定値", "min" => "下限値", "max" => "上限値" } }
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
