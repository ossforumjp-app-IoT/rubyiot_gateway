#!/usr/bin/ruby -Ku
# encoding: utf-8
require "logger"

class ImageFile

  attr_reader :flag, :filepath

  def initialize
    @filepath = "/tmp/capture_image.jpg"
    @flag = false
    @log = Logger.new("/tmp/image_file.log")
    @log.level = Logger::DEBUG
  end


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

