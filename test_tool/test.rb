#!/usr/bin/ruby -Ku

require_relative "gw"
require_relative "massive_data"

puts "ダミーゲートウェイプログラム開始"
gw_num = ARGV[0].to_i #ゲートウェイの数
index_s = ARGV[1].to_i #ゲートウェイのインデックスナンバー
index_e = index_s + gw_num - 1
request_times = ARGV[2].to_i #1台のGWがリクエストする回数

id = Array.new
gw = Array.new

puts "ダミーゲートウェイの生成、ログイン、センサデバイスID取得中..."
for i in index_s..index_e do
	puts i
	gw[i] = Gateway.new("aaa","aaa",i+1)
	gw[i].login
	id[i] = gw[i].post_device("#{i+1}")
end


puts "ダミーゲートウェイ#{gw_num}台生成完了"
thread = []
data = MassiveData.new.make_data
puts "大量データ生成完了"

puts "データ送信開始！！"

for i in index_s..index_e do
	thread << Thread.new(i) do |j|
		request_times.times do
			gw[j].store_data(id[j],data.pop)
		end
	end
end
thread.each {|t| t.join}

puts "ダミーゲートウェイ　ログアウト中..."
for i in index_s..index_e do
	gw[i].logout
end

puts "ダミーゲートウェイプログラム終了"
