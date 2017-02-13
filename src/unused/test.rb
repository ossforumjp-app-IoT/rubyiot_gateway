require "logger"

class Logger1

  @@LEVEL = Logger::DEBUG

  attr_reader :logger

  def initialize
    @logger = Logger.new("/tmp/test.log")
    @logger.level = @@LEVEL
  end

end

class Hoge1 < Logger1 

  def initialize
    super()
    self.logger.debug("#{self.class.name}: #{__method__}");
  end

end

class Hoge2 < Logger1

  def initialize
     super()
     self.logger.debug("#{self.class.name}: #{__method__}");
  end

end

while 1
  Hoge1.new()
  Hoge2.new()
end  



