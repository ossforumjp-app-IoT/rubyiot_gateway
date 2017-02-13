#!/usr/bin/ruby -Ku
# encoding: utf-8

require './image_file'
require 'minitest/autorun'
require "test/unit"


class TestImageFile < Test::Unit::TestCase

  def test_init
    assert_nothing_raised( RuntimeError ) { ImageFile.new() }
  end


  def test_capture
    tmp = ImageFile.new

    puts "Run the following commnad"
    puts "sudo ruby webcam.rb"
    sleep(5)


    trap("SIGINT") { throw :ctrl_c }
         catch :ctrl_c do
           begin
             puts "Click ctrl button on the box to capture image"
             puts "Start ...."
             sleep(10)
             puts "Check image existance"
             puts tmp.search()
             sleep(2)
             puts "Delete Image"
             tmp.delete()
             sleep(10)
             puts "Check image existance"
             puts tmp.search()
           rescue Exception
             puts "Exit"
           end while true
         end

  end


end
