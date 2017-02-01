#!/usr/bin/ruby -Ku
# encoding: utf-8
require "logger"

class ImageFile

  def initialize
    #dir = "/home/tasaka/rubyiot_gateway/src"
    dir = "/home/pi/work_tasaka/rubyiot_gateway/src"
    #dir = "/home/pi/test_image_file"
    #filename = "raspberrypi.png"
    filename = "20161218.JPG"
    #filename = ""
    @filepath = dir + "/" + filename
    @flag = false
    @log = Logger.new("/tmp/image_file.log")
    @log.level = Logger::DEBUG
  end

  attr_reader :flag, :filepath

  def search
    @flag = true if File.exist?(@filepath)
    @log.debug("#{self.class.name}: #{__method__}  File flag :#{@flag}")
    return @flag
  end

  # 指定したパスのファイルを削除するメソッド
  def delete
    begin
      File.delete(@filepath)
      @flag = false
    rescue => e
      @log.error("#{self.class.name} : #{__method__} : #{e.message}");
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
