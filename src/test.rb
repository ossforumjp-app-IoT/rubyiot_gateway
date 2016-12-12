#!/usr/bin/ruby -Ku

require "thread"



str = "abcd"
len=3
p str.slice!(0,len)
p str
