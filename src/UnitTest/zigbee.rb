#!/usr/bin/ruby -Ku
# encoding: utf-8

require "./zigbee"
require "test/unit"


class TestZigbee <  Test::Unit::TestCase

  def test_init
    puts __method__
    z = Zigbee.new
  end

  def test_dummy
    puts __method__
    z = Zigbee.new

    trap("SIGINT") { throw :ctrl_c }

      catch :ctrl_c do
        begin
          sleep(1)
          puts Time.now
          puts data = z.recv()
          z.send(1, 11.0, 30.0, data["addr"])
        rescue Exception
          puts "Exit"
        end while true
      end

  end

end