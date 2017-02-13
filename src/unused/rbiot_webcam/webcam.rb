require 'date'
require 'pi_piper'


def webcam_cmd
	cam_cmd = "fswebcam"
	cam_opt = "-r 640x480 -S 30 -F 1 -D 0"
	cam_dir = "./"
	today = DateTime.now
	filename = sprintf("%04d%02d%02d%02d%02d%02d.jpg", 
				today.year.to_s,
		 		today.mon.to_s,
				today.day.to_s,
				today.hour.to_s,
				today.min.to_s,
				today.sec.to_s)

	cmd = cam_cmd + " " + cam_opt + " " + cam_dir + filename
	cmd
end

$last_date = Time.now - 5
$last_key = true
PiPiper::after :pin => 18, :goes=> :high do
	now = Time.now
	if $last_key then
		system webcam_cmd if (now - $last_date) > 5
		$last_date = Time.now
		$last_key = false
	else
		$last_key = true
	end
	#system webcam_cmd if value == :high
end

PiPiper.wait
