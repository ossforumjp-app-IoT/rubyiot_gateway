#!/usr/bin/ruby -Ku
# encoding: utf-8
require "logger"

class ImageFile

  attr_reader :flag, :filepath

  def initialize
#    @filepath = "/tmp/capture_image.jpg"
    @filepath = "/home/tasaka/rubyiot_gateway/src/picamera/rmagick_img/upload/"
    @flag = false
    @log = Logger.new("/tmp/image_file.log")
    @log.level = Logger::DEBUG
  end


  def search
    @flag = false
    @flag = true if (File.exist?(@filepath + "1.jpg") ||
                     File.exist?(@filepath + "2.jpg") ||
                     File.exist?(@filepath + "3.jpg") ||
                     File.exist?(@filepath + "4.jpg") ||
                     File.exist?(@filepath + "5.jpg"))
    @log.debug("#{self.class.name}: #{__method__}  File flag :#{@flag}")
    return @flag
  end

  # 指定したパスのファイルを削除するメソッド
  def delete(file)
    begin
      File.delete(@filepath + file)
      @flag = false
    rescue => e
      @log.error("#{self.class.name} : #{__method__} : #{e.message}");
    end
  end

end

=begin
image = ImageFile.new
puts image.search()
puts image.search()
puts image.delete("1.jpg")
puts image.delete("2.jpg")
puts image.search()
puts image.delete("3.jpg")
puts image.delete("4.jpg")
puts image.delete("5.jpg")
puts image.search()
=end
