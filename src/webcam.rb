require 'date'
require 'pi_piper'

module WEBCAME_OPTS
  GPIO_PIN = 18   # th pin
  PERIOD = 5      # seconds
end

def webcam_cmd
	cam_cmd = "fswebcam"
	cam_opt = "-r 640x480 -S 30 -F 1 -D 0"
	filename = "/tmp/capture_image.jpg"

	cmd = cam_cmd + " " + cam_opt + " " + filename
	cmd
end

$last_date = Time.now - WEBCAME_OPTS::PERIOD
$last_key = true
PiPiper::after :pin => WEBCAME_OPTS::GPIO_PIN, :goes=> :high do
	now = Time.now
	if $last_key then
		system webcam_cmd if (now - $last_date) > WEBCAME_OPTS::PERIOD
		$last_date = Time.now
		$last_key = false
	else
		$last_key = true
	end
end

PiPiper.wait
