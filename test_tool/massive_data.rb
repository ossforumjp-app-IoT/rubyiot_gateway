require 'json' 

module MassiveData

	START = Time.now - 5 * 24 * 60 * 60 
	INTERVAL = 3 
	SPAN = 5 * 24 * 60 * 60 / INTERVAL 

	r = Random.new(Random.new_seed) 
	t = START 

	v = case t.mon 
 	 when 12, 1, 2; 16 
 	 when 3, 4, 10, 11; 18 
 	 when 5, 6, 9; 20 
 	 when 7, 8; 24 
	end 

File.open("format.txt", "w") do |file|
i=0
(0..SPAN).each {
  if i == 10000 then 
    break
  end
  i+=1
  adj = case t.hour 
    when 15..23, 0..5 
      -0.0003 
    when 6..14 
      0.0005 
  end 

  v += r.rand * 0.04 - 0.02 + adj 
  t += INTERVAL 

	ss = sensor_status.rand(0..3)
	fs = fan_status.rand(0..1)
	ts = temp_status.rand(0..2)

  case t.mon 
   when 12, 1, 2 
     if v > 20 
       v -= 0.1 
     elsif v < 12 
       v += 0.1 
     end 
   when 3, 4, 10, 11 
     if v > 25 
       v -= 0.1 
     elsif v < 15 
       v += 0.1 
     end 
   when 5, 6, 9 
     if v > 27 
       v -= 0.1 
     elsif v < 20 
       v += 0.1 
     end 
   when 7, 8 
     if v > 33 
       v -= 0.1 
     elsif v < 25 
       v += 0.1 
     end 
  end 
  file.printf("%s\n", "#{addr},#{lsb64},#{msb16},#{lsb16},#{ss},#{fs},#{ts},+#{v.round(1)}")
} 

end #file
end
