#!/bin/sh

#GW　1台で1リクエストで実行
#ruby main.rb 1 0 1 

#100GWを100リクエストで10プロセスで実行
ruby main.rb 100 0 100 &
ruby main.rb 100 10 100 &
ruby main.rb 100 20 100 &
ruby main.rb 100 30 100 &
ruby main.rb 100 40 100 &
ruby main.rb 100 50 100 &
ruby main.rb 100 60 100 &
ruby main.rb 100 70 100 &
ruby main.rb 100 80 100 &
ruby main.rb 100 90 100 &
