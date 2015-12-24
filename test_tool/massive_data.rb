require 'time' 

class MassiveData

	def initialize
		@start = Time.now - 5 * 24 * 60 * 60 
		@interval = 3 
		@span = 5 * 24 * 60 * 60 / @interval

		@r = Random.new(Random.new_seed) 
		@t = @start
		@q = Queue.new
		@v = case @t.mon 
					when 12, 1, 2; 16 
					when 3, 4, 10, 11; 18 
					when 5, 6, 9; 20 
					when 7, 8; 24 
				end 
	end

	def make_data
		i=0
		(0..@span).each {
			"""
			if i == 10000 then 
				break
			end
			"""
			i+=1
			adj = case @t.hour 
			when 15..23, 0..5 
				-0.0003 
			when 6..14 
				0.0005 
			end 
			@v += @r.rand * 0.04 - 0.02 + adj 
			@t += @interval
  
			case @t.mon 
				when 12, 1, 2 
					if @v > 20 
						@v -= 0.1 
					elsif @v < 12 
						@v += 0.1 
					end 
				when 3, 4, 10, 11 
					if @v > 25 
						@v -= 0.1 
					elsif @v < 15 
						@v += 0.1 
					end 
				when 5, 6, 9 
					if @v > 27 
						@v -= 0.1 
					elsif @v < 20 
						@v += 0.1 
					end 
				when 7, 8 
					if @v > 33 
						@v -= 0.1 
					elsif @v < 25 
						@v += 0.1 
					end 
			end 
			@q.push(@v)
		} 
		return @q
	end
end
