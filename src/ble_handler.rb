#!/usr/bin/ruby -Ku
## encoding: utf-8
require 'thread'

class BleHandler

  def initialize()
    @target_mac = "00:A0:50:CC:92:59"
    btmon = "btmon"
    @pin1, @pout1 = IO.pipe
    Thread.new {
      fork {
        @pin1.close
        STDOUT.reopen(@pout1)
        #cmd = "stdbuf -o0 #{btmon}"
        cmd = "#{btmon}"
        exec cmd
      }
    }


  end
 
  def analyze()
    rssi = 1
    while true
       line1 = @pin1.gets
       if line1[8..15].to_s == "Address:" then
          if @target_mac == line1[17..33] then
             while true
                line2 = @pin1.gets
                if line2[8..12] == "RSSI:" then
                   rssi = line2[14..16].to_i
                   break
                end
             end
             break
          end
       end
    end
    return rssi
  end

  def get_rssi()
    rssi = analyze()
    return rssi
  end


 def flush()
    @pin1.flush()
    @pout1.flush()
 end
end

=begin
b = BleHandler.new
while true
  puts b.get_rssi
end

=end
