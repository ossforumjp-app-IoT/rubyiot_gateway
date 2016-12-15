#!/usr/bin/ruby -Ku

require_relative 'cloud_db_api'
require 'objspace'

class SensingDataHandler

  def initialize
    @cloud = CloudDatabaseAPI.new
    p @cloud.login()

  end

  def store_sensing_data(sensor_id, data)
    t = Thread.new {
      res = @cloud.sotre_sensing_data(sensor_id, data)
    }
  end


  # TODO Destructorを実装したい
  # それまでの代わりのメソッド
  def logout
    @cloud.logout()
  end
end



# Debug

if $0 == __FILE__ then

  begin
    sdh = SensingDataHandler.new
  end
  
end

