require '../data_handler'
require "test/unit"


class TestDataHandler < Test::Unit::TestCase

  # Testing parameters
  @gateway_id = 1
  @addr =  "0013a20040b189bc"

  @data = {"addr" => @addr, "temp" => "21"}
  @min = 20
  @max = 40

  @status    = "status"

  def test_typecheck
    puts "====================================="
    assert_nothing_raised( RuntimeError ) { DataHandler.new(@gateway_id) }
  end

  d_hdr = DataHandler.new(1)

  def test_get_monitoring_range
    puts "====================================="
    puts __method__
    data = {"addr" => @addr, "temp" => "21"}
#    assert_nothing_raised( RuntimeError ) { DataHandler.new(@gateway_id).get_monitoring_range(@data) }
    puts DataHandler.new(@gateway_id).get_monitoring_range(data)
  end

  def test_get_operation
    puts "====================================="
    puts __method__
#    assert_nothing_raised( RuntimeError ) { DataHandler.new(@gateway_id).get_operation() }
    puts DataHandler.new(@gateway_id).get_operation();
  end

  def test_notify_alert
    puts "====================================="
    puts __method__
    data = {"addr" => @addr, "temp" => "21"}
#    assert_nothing_raised( RuntimeError ) { DataHandler.new(@gateway_id).notify_alert(@data, @min, @max) }
    puts DataHandler.new(@gateway_id).notify_alert(data, @min, @max);
  end

  def test_register_id
    puts "====================================="
    puts __method__
    data = {"addr" => @addr, "temp" => "21"}
#    assert_nothing_raised( RuntimeError ) { DataHandler.new(@gateway_id).register_id(@addr) }
    puts DataHandler.new(@gateway_id).register_id();
  end

  def test_set_operation_status
    puts "====================================="
    puts __method__
#    assert_nothing_raised( RuntimeError ) { DataHandler.new(@gateway_id).set_operation_status(@gateway_id, @status) }
    puts DataHandler.new(@gateway_id).set_operation_status(@gateway_id, @status);
  end

  def test_store_sensing_data
    puts "====================================="
    puts __method__
    data = {"addr" => @addr, "temp" => "21"}
#    assert_nothing_raised( RuntimeError ) { DataHandler.new(@gateway_id).store_sensing_data(@data) }
    puts DataHandler.new(@gateway_id).store_sensing_data(data);
  end


end