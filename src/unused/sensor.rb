#!/usr/bin/ruby -Ku
# encoding: utf-8

class Sensor

  attr_accessor :max, :min, :addr

  def initialize(params = {})
    @max = params.fetch(:max, "28")
    @min = params.fetch(:min, "18")
    @addr = params.fetch(:addr, nil);
  end


end
