
# センサデータのデバック用クラス
class SerialDummyPort

	# 初期化
	# @param [String] @DATA センサのデータ
	def initialize()
		@DATA = "~\x00\x18\x90\x00\xA2\x00@\xB1\x89\xBC\xBB\xA5\x013,0,+023.1,0\xED"
	end

	# データを一定のbyte数だけ文字列を返し、返した文字列をデータから削除するメソッド
	# @param [Interger] len byte数
	# @return [String] byte数だけの文字列を返す
	def read(len=1)
		return @DATA.slice!(0,len)
	end

	# データ列を元に戻すメソッド
	# (本来のserialportのflush_inputはバッファとして持っているデータを全て消すメソッド)
	def flush_input
		@DATA = "~\x00\x18\x90\x00\xA2\x00@\xB1\x89\xBC\xBB\xA5\x013,0,+023.1,0\xED"
	end

	# データを書き込んで送信するメソッド
	#	@param [Array] @data 送信するデータ
	def write(data)
		p "Send data: #{data}"
	end

end

if $0 == __FILE__ then 
  sdp = SerialDummyPort.new
  p sdp.read()
  p sdp.read(2)
  p sdp.flush_input
end

