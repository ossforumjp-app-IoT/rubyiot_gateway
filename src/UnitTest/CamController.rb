#!/usr/bin/ruby -Ku
# encoding: utf-8

require "./CamController"
require "test/unit"

class TestCamController <  Test::Unit::TestCase

  def test_typecheck
    puts "====================================="
    CamController.new
  end

  def test_exec
    puts __method__
    $cam = CamController.new();


    trap("SIGINT") { throw :ctrl_c }

      catch :ctrl_c do
        begin
          $cam.exec()
        rescue Exception
          puts "Exit"
        end
      end


  end

end
