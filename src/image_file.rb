#!/usr/bin/ruby -Ku

class ImageFile

  def initialize
    dir = "/home/tasaka/rubyiot_gateway/src"
    filename = "raspberrypi.png"
    @filepath = dir + "/" + filename
    @flag = false
  end

  attr_reader :flag, :filepath

  def search
    @flag = true if File.exist?(@filepath)
  end

  # 指定したパスのファイルを削除するメソッド
  def delete
    begin
    File.delete(@filepath)
    rescue e
    p '---------------------------------'
    p "File delete error"
    p e.message
    p '---------------------------------'
    end
  end 

end

#Debug
if $0 == __FILE__ then
  f = ImageFile.new
  p f.flag
  f.search
  p f.flag
  f.delete()
end
