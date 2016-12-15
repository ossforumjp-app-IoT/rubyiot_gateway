#!/usr/bin/ruby -Ku


class Sensor

  def initialize(max, min)
    @max = max
    @min = min
  end

  attr_accessor :max, :min

end
