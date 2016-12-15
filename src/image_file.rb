#!/usr/bin/ruby -Ku


class ImageFile

  def initialize
    @dir = "/home/tasaka/rubyiot_gateway/src"
    @filename = "raspberrypi.png"
    @flag = false
  end

  attr_reader :flag

  def search
    @flag = true if File.exist?(@dir)
  end
  
end

#Debug
if $0 == __FILE__ then
  f = ImageFile.new
  p f.flag
  f.search
  p f.flag

end
