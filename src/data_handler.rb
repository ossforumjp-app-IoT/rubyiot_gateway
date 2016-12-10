
require "cloud_db_api"

class SensingDataHandler

  def initialize
    @cloud = CloudDataBaseAPI.new
    @cloud.login
  end

  def store_sensing_data(sensor_id, data)
    t = Thread.new {
     res = @cloud.sotre_sensing_data(sensor_id, data)
    }
  end

end
