#!/usr/bin/ruby -Ku
# encoding: utf-8

require '../gateway'
require 'minitest/autorun'
#require "test/unit"


class TestDataHandler < Minitest::Test #Test::Unit::TestCase

  @gateway_id = 1

  def test_typecheck
    puts "====================================="
    puts __method__
    assert_nothing_raised( RuntimeError ) { Gateway.new(@gateway_id) }
  end

  def test_def_threads_pool
    puts "====================================="
    puts __method__
    puts Gateway.new(@gateway_id).def_threads_mapping()
  end


  def test_main
    puts "====================================="
    puts __method__
    puts Gateway.new(@gateway_id).main()
  end

end