#!/usr/bin/ruby -Ku

require "thread"

class Hoge
  
  def initialize
    @q = Queue.new
    @q.push(:a)
    @q.push(:b)
    @q.push(:c)
  end

  def get
    @q.pop
  end

end

h = Hoge.new
p h.get
