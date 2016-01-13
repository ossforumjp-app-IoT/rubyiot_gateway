#!/usr/bin/ruby -Ku

require 'net/http'
require 'uri'
require "json"
require "benchmark"
require "httpclient"
require "digest/sha2"

class Gateway

	def initialize(usr, pwd, gwid)
		#puts __method__
		@server = "http://rubyiot.rcloud.jp"
		@uri = "#{@server}/api"
		@usr = usr
		@pwd = pwd
		@http = HTTPClient.new
		#@http = HTTPClient.new("PROXY_URL:PROXY_PORT")
		#@http.set_proxy_auth("LOGINID","PASSWD")

		@http.set_auth(@server, @usr, Digest::SHA256.hexdigest(@pwd))
		@gwid = gwid
		@f = File.open("gateway#{@gwid}.log","w")
	end

	def login
		#puts __method__
		payload = {
			:username => @usr,
			:password_hash => Digest::SHA256.hexdigest(@pwd)
		}.to_json
		res = ""
		begin
		dt = Benchmark.realtime do	
			res = @http.post("#{@uri}/login",payload)
		end
		result = res.body
		log(__method__,result,dt)
		rescue
		result = "ERROR!!"
		log(__method__,result)
		end

	end
	
	def logout
		#puts __method__
		res = ""
		begin
		dt = Benchmark.realtime do	
			res = @http.get("#{@uri}/logout")
		end
		result = res.body
		log(__method__,result,dt)
		rescue
		result = "ERROR!!"
		log(__method__,result)
		end

		@f.close
	end

	def post_device(id)
		#puts __method__
		payload = {
			:gateway_uid => @gwid,
			:device_uid => id,
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
		begin
		dt = Benchmark.realtime do	
			res = @http.post("#{@uri}/device",payload)
		end
		result = res.body
		log(__method__,result,dt)
		rescue
		result = "ERROR!!"
		log(__method__,result)
		return 0
		end

		return JSON.parse(result).values[0][0]["id"]
	end

	def set_monitor_range(id, min, max)
		#puts __method__
		payload = {
			id => {
				:min => min,
				:max => max 
			}
		}.to_json
		res = ""
		begin
		dt = Benchmark.realtime do	
			res = @http.post("#{@uri}/monitor",payload)
		end
		result = res.body
		log(__method__,result,dt)
		rescue
		result = "ERROR!!"
		log(__method__,result)
		end
	end


	def store_data(id, data)
		#puts __method__
		payload = {id => data}.to_json
		res = ""
		begin
		dt = Benchmark.realtime do
			res = @http.post("#{@uri}/sensor_data",payload)
		end
		result = res.body
		log(__method__,result,dt)
		rescue
		result = "ERROR!!"
		log(__method__,result)
		end
	end

	def notify_alert(id, min, max, v)
		#puts __method__
		payload = {
			id => {
				:value => v, 
				:min => min, 
				:max => max
			}
		}.to_json
		res = ""
		begin
		dt = Benchmark.realtime do
			res = @http.post("#{@uri}/sensor_alert",payload)
		end
		result = res.body
		log(__method__,result,dt)
		rescue
		result = "ERROR!!"
		log(__method__,result)
		end

	end

	def log(method,result,dt="unknown")
		@f.printf("===================================\n")
		@f.printf("Method: #{method}\n")
		@f.printf("Diff time: #{dt}\n")
		@f.printf("Response:\n")
		@f.printf("#{result}\n")
		@f.printf("===================================\n")
	end
end #Gateway
