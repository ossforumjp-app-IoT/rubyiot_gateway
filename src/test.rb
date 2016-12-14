#!/usr/bin/ruby -Ku

require "yaml"
require "serialport"

class Zigbee
  @@xbee = YAML.load_file "./xbee.yml"

  def initialize

    spconf = @@xbee["serialport"]
    begin
    if spconf["device"] == "dummy"
      @sp = SerialDummyPort.new
    else
      @sp = SerialPort.new(spconf["device"], spconf["boudrate"],
                           spconf["databits"], spconf["stopbits"], 
                           spconf["parity"])
    end
    rescue => e
      p '---------------------------------'
      p "SerialPort open error"
      p e.message
      p '---------------------------------'
    end
  end

  def write
    data = ["7E002310010013a20040b189bcfffe0000302c312c2b3033302e302c2b3031312e30ea"]
    @sp.write(data.pack("H*"))
  end

end

if $0 == __FILE__ then

  z = Zigbee.new
  z.write()

end


