#!/usr/bin/ruby -Ku

require "thread"

class Hoge
  def foo(str)
    p str
  end

end

def foo(str)
  p str
end


time = Time.now
if time < Time.now then
 p "aa"
end

h = Hoge.new

worker = Hash.new

worker["AAA"] = lambda {|str|
 Thread.new {
  for t in 1..5
    h.foo(str)
    sleep 3
  end
 "www"
 }
}

p worker["AAA"].call("aaa")

sleep 10
