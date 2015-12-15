#!/usr/bin/ruby -Ku

require 'net/http'
require 'uri'
require "json"
require "benchmark"
require "httpclient"
require "digest/sha2"

class Gateway

	def initialize(usr, pwd, gwid)
		puts __method__
		@server = "http://rubyiot.rcloud.jp"
		@uri = "#{@server}/api"
		@usr = usr
		@pwd = pwd
		@http = HTTPClient.new("URL:PORT")
		@http.set_proxy_auth("USR","PWD")
		@http.set_auth(@server, @usr, Digest::SHA256.hexdigest(@pwd))
		@gwid = gwid
		@f = File.open("gateway#{@gwid}.log","w")
	end

	def login
		puts __method__
		payload = {
			:username => @usr,
			:password_hash => Digest::SHA256.hexdigest(@pwd)
		}.to_json
		res = ""
		dt = Benchmark.realtime do	
			res = @http.post("#{@uri}/login",payload)
		end
		@f.printf("===================================\n")
		@f.printf("Method: #{__method__}\n")
		@f.printf("Diff time: #{dt}\n")
		@f.printf("Response:\n")
		if res.body.class != String then
			@f.printf("#{JSON.parse(res.body)}\n")
		else
			@f.printf("#{res.body}\n")
		end
		@f.printf("===================================\n")
	end
	
	def logout
		puts __method__
		res = ""
		dt = Benchmark.realtime do	
			res = @http.get("#{@uri}/logout")
		end
		@f.printf("===================================\n")
		@f.printf("Method: #{__method__}\n")
		@f.printf("Diff time: #{dt}\n")
		@f.printf("Response:\n")
		if res.body.class != String then
			@f.printf("#{JSON.parse(res.body)}\n")
		else
			@f.printf("#{res.body}\n")
		end
		@f.printf("===================================\n")

		@f.close
	end

	def post_device(devid)
		puts __method__
		payload = {
			:gateway_uid => @gwid,
			:device_uid => devid,
			:class_group_code => "0x00",
			:class_code => "0x00",
			:properties => [
				{
					:class_group_code => "0x00",
					:class_code => "0x00",
					:property_code => "0x30",
					:type => :sensor,
				},
				{
					:class_group_code => "0x00",
					:class_code => "0x00",
					:property_code => "0x31",
					:type => :controller
				}
			]
		}.to_json
		res = ""
		dt = Benchmark.realtime do	
			res = @http.post("#{@uri}/device",payload)
		end
		@f.printf("===================================\n")
		@f.printf("Method: #{__method__}\n")
		@f.printf("Diff time: #{dt}\n")
		@f.printf("Response:\n")
		if res.body.class != String then
			@f.printf("#{JSON.parse(res.body)}\n")
		else
			@f.printf("#{res.body}\n")
		end
		@f.printf("===================================\n")
		#return is sensor id?
		return JSON.parse(res.body).values[0][0]["id"]
	end

	def set_monitor_range(id, min, max)
		puts __method__
		payload = {
			id => {
				:min => min,
				:max => max 
			}
		}.to_json
		res = ""
		dt = Benchmark.realtime do	
			res = @http.post("#{@uri}/monitor",payload)
		end
		@f.printf("===================================\n")
		@f.printf("Method: #{__method__}\n")
		@f.printf("Diff time: #{dt}\n")
		@f.printf("Response:\n")
		if res.body.class != String then
			@f.printf("#{JSON.parse(res.body)}\n")
		else
			@f.printf("#{res.body}\n")
		end
		@f.printf("===================================\n")
	end


	def store_data(id, data)
		puts __method__
		payload = {id => data}.to_json
		res = ""
		dt = Benchmark.realtime do
			res = @http.post("#{@uri}/sensor_data",payload)
		end

		@f.printf("===================================\n")
		@f.printf("Method: #{__method__}\n")
		@f.printf("Diff time: #{dt}\n")
		@f.printf("Response:\n")
		if res.body.class != String then
			@f.printf("#{JSON.parse(res.body)}\n")
		else
			@f.printf("#{res.body}\n")
		end
		@f.printf("===================================\n")
	end

	def notify_alert(id, min, max, v)
		puts __method__
		payload = {
			id => {
				:value => v, 
				:min => min, 
				:max => max
			}
		}.to_json
		res = ""
		dt = Benchmark.realtime do
			res = @http.post("#{@uri}/sensor_alert",payload)
		end
		@f.printf("===================================\n")
		@f.printf("Method: #{__method__}\n")
		@f.printf("Diff time: #{dt}\n")
		@f.printf("Response:\n")
		if res.body.class != String then
			@f.printf("#{JSON.parse(res.body)}\n")
		else
			@f.printf("#{res.body}\n")
		end
		@f.printf("===================================\n")
	end

	def process_data()
		puts __method__
	end

end #Gateway
