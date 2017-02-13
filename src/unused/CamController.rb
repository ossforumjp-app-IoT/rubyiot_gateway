require 'pi_piper'
require 'date'
include PiPiper

# CamController class's parameter
module CAM_PARAMS
  # Camera's controller button gpio pin
  CTRL_PIN = 18
  # Delay time between 2 times of capturing
  DELAY_TIME = 5
  # fswebcam options
  OPTS = "-r 640x480 -S 30 -F 1 -D 0"
  IMG_DIR = "/tmp/"
end

# monitor camera's control button status
# @param [Boolean] is_pushed  whether control button was pushed?
class CamController

  def exec
    $last_date = Time.now - 5
    $last_key = false

    PiPiper::after :pin => CAM_PARAMS::CTRL_PIN, :goes=> :high do
      now = Time.now
      if $last_key then
        if (now - $last_date) > CAM_PARAMS::DELAY_TIME

          today = DateTime.now
          filename = sprintf("%04d%02d%02d%02d%02d%02d.jpg",
                today.year.to_s,
                today.mon.to_s,
                today.day.to_s,
                today.hour.to_s,
                today.min.to_s,
                today.sec.to_s)

          cmd =  "fswebcam " + CAM_PARAMS::OPTS + " " + CAM_PARAMS::IMG_DIR + filename
          puts cmd
          status = system(cmd)

          if status
            print "capture image success"
          else
            print "capture image failed"
          end

        end
        $last_date = Time.now
        $last_key = false
      else
        $last_key = true
      end
    end

    PiPiper.wait

  end


end
