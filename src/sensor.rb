#!/usr/bin/ruby -Ku


class Sensor

  def initialize(min, max)
    @min = min
    @max = max
    @addr = nil
  end

  attr_accessor :max, :min, :addr

end
