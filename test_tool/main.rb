#!/usr/bin/ruby -Ku

require_relative "gw"
#require_relative "massive_data"

gw1 = Gateway.new("test1","test1",1)

gw1.login
gw1.logout
