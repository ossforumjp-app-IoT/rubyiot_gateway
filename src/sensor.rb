#!/usr/bin/ruby -Ku
# encoding: utf-8

class Sensor

  def initialize(min, max)
    @min = min
    @max = max
    @addr = nil
  end

  attr_accessor :max, :min, :addr

end
