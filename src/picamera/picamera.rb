require 'date'
require 'opencv'
require 'rmagick'

#$distort = :barrel
$distort = :none

class Picamera
    def initialize
        @tmp_dir = "rmagick_img/tmp/"
        @upload_dir = "rmagick_img/upload/"
        @save_format = ".jpg"
        @rmagick_format = 'JPEG'
        if $distort == :barrel then
            @barrel_points = [0, -0.21, 0, 1.3,  # kx
                              0, -0.21, 0, 1.3]  # ky
        end
    end

    def save
        today = DateTime.now
=begin
        save_time = sprintf("%04d%02d%02d%02d%02d%02d",
            today.year.to_s,
            today.mon.to_s,
            today.day.to_s,
            today.hour.to_s,
            today.min.to_s,
            today.sec.to_s)
=end
        5.times do |i|
             filename = i.to_s + @save_format
#            filename = save_time + "_" + i.to_s + @save_format
#            filename = save_time + @save_format
            capture = OpenCV::CvCapture.open
            if $distort == :none then
                capture.width = 320
                capture.height = 240
            elsif $distort == :barrel then
                capture.width = 360
                capture.height = 270
            end
            mat = capture.query.to_CvMat
            capture.close
            if mat != nil then
               # save tmp image
                mat.save(@tmp_dir + filename)
                # compress jpeg and save upload image
                if $distort == :none then
                    img = Magick::Image.read(@tmp_dir + filename).first
                    img.format = @rmagick_format
                    img.write(@upload_dir + filename){self.quality = 32}
                    img.destroy!
                elsif $distort == :barrel then
                    img = Magick::Image.read(@tmp_dir + filename).first
                    img = img.distort(Magick::BarrelDistortion, @barrel_points, TRUE).crop(20, 15, 320, 240)
                    img.format = @rmagick_format
                    img.write(@upload_dir + filename){self.quality = 32}
                    img.destroy!
                end
                # delete tmp image
                File.delete(@tmp_dir + filename)
            end
        end
    end
end


#------ for check ------
=begin

camera = Picamera.new

camera.save

=end
#------ for check ------
