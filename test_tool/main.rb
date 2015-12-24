#!/usr/bin/ruby -Ku

require_relative "gw"
require_relative "massive_data"

puts "ダミーゲートウェイプログラム開始"
gw_num = 1 
request_times = 1
id = Array.new
gw = Array.new

puts "ダミーゲートウェイの生成、ログイン、センサデバイスID取得中..."
for i in 0...gw_num do
	gw[i] = Gateway.new("aaa","aaa",i+1)
	gw[i].login
	id[i] = gw[i].post_device("#{i+1}")
end


puts "ダミーゲートウェイ#{gw_num}台生成完了"
thread = []
data = MassiveData.new.make_data
puts "大量データ生成完了"

puts "データ送信開始！！"
gw_num.times do |i|
	thread << Thread.new(i) do |j|
		request_times.times do |k|
			gw[j].store_data(id[j],data.pop)
		end
	end
end
thread.each {|t| t.join}

puts "ダミーゲートウェイ　ログアウト中..."
for i in 0...gw_num do
	gw[i].logout
end


puts "ダミーゲートウェイプログラム終了"
