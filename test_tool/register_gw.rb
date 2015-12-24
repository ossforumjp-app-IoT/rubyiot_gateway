#!/usr/bin/ruby -Ku
#
require 'net/http'
require 'uri'
require "json"
require "benchmark"
require "httpclient"
require "digest/sha2"

gw_num=100

#http = HTTPClient.new("PROXY_URL:PROXY_PORT")
#http.set_proxy_auth("LOGINID","PASSWD")
http = HTTPClient.new
http.set_auth("http://rubyiot.rcloud.jp", "aaa", Digest::SHA256.hexdigest("aaa"))

payload = {
	:username => "aaa",
	:password_hash => Digest::SHA256.hexdigest("aaa")
}.to_json

res = http.post("http://rubyiot.rcloud.jp/api/login",payload)

for i in 0...gw_num do

	payload = {
		:hardware_uid => i+1,
		:name => "gw#{i+1}",
	}.to_json
	res = http.post("http://rubyiot.rcloud.jp/api/gateway_add",payload)
	puts "#{res.body} gw#{i+1}"

end


res = http.post("http://rubyiot.rcloud.jp/api/logout",payload)
