# = class SerialDummyFile
# == 概要
# 本来であれば、IOクラスを継承して作るところですが、
# シリアルポートがない場合に、入力用ファイル、出力用ファイルを
# 使って、入出力を確認するために、read、write、flush_input
# だけを実装したクラスです。
class SerialDummyFile
  # == 特異メソッド
  # * new(input: "serial input dummy file", output: "serial output dummy file")
  # インプット用のファイルと、アウトプット用のファイルを指定して、擬似的なシリアル通信の
  # オブジェクトを生成します。
  # 引数を指定しない場合は、カレントディレクトリのtmp以下にserial_dummy_inputと
  # serial_dummy_outputというファイルを作成します。
  def initialize(input: "tmp/serial_dummy_input", output: "tmp/serial_dummy_output")
    unless File.exist?(input)
      File.open(input, "w").close
    end

    unless File.exist?(output)
      File.open(output, "w").close
    end

    @input_file = File.open(input, "r+")
    @output_file = File.open(output, "a")
  end

  # == インスタンスメソッド
  # * input_file
  # * input_file=("serial output dummy file")
  # * output_file
  # * output_file=("serial input dummy file")
  attr_accessor :input_file, :output_file

  # * read
  def read
    @input_file.read
  end

  # * read(byte)
  def read(byte)
    @input_file.read(byte)
  end

  # * write(output)
  def write(output)
    @output_file << output
  end

  # * flush_input
  def flush_input
    @input_file.truncate(0)
    @input_file.rewind
  end
end
