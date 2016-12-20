#!/usr/bin/ruby -Ku

require "thread"

def hoge(x)
  p x.call(3)
end

l = lambda {|x| x * x}
k = lambda {|x| 1 * x}

hoge(l)
hoge(k)
