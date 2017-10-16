#!/usr/bin/ruby -Ku
## encoding: utf-8
require "thread"

array = Array.new()

array.push(5)
array.push(4)
array.push(3)
array.push(2)
array.push(1)
puts array
puts array.inject(:+)
puts "aaaa"
array.shift()
array.shift()
puts array
puts "aaaa"
array.push(11)
array.push(10)
puts array
puts "aaaa"
array.shift()
array.shift()
puts array

