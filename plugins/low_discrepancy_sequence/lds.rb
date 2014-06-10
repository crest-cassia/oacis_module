
module LowDiscrepancySequence
	@prime_array = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29,
									31, 37, 41, 43, 47, 53, 59, 61, 67, 71,
									73, 79, 83, 89, 97, 101, 103, 107, 109, 113,
									127, 131, 137, 139, 149, 151, 157, 163, 167, 173,
									179, 181, 191, 193, 197, 199, 211, 223, 227, 229
								]

  # Van Der Corupt (one dimension)
	def self.vdC(index, base)
		result = 0.0
	  f = 1.0 / base
	  i = index
	  while i > 0.0
	  	result += (i % base)*f
	  	i = i/base
	  	f = f/base
	  end
	  result
	end

	# Halton (two or more dimensions)
	def self.halton(index, dim)
		arr = []
		dim.times{|j|
			arr << vdC(index,@prime_array[j])
		}
		arr
	end
end


# test
if __FILE__==$0
	require_relative 'lds'
	
	# sample per axis 
	n = 10000000
	axis_num = 2

	# simple random sampling
	p "random sampling"
	count = 0
	n.times.each{|i|
		y = 0.0
		axis_num.times{
			x = rand
			y += x*x
		}
		count += 1 if y < 1.0
	}	
	p rs_pi = 4.0*(count.to_f/n.to_f)

	# quasi random sampling (halton)
	p "quasi random sampling (halton sequence)"
	count = 0
	n.times.each{|i|
		arr =	LowDiscrepancySequence.halton(i, axis_num)
		y = arr.map{|x| x*x}.inject(:+)
		count += 1 if y < 1.0
	}	
	p qrs_pi = 4.0*(count.to_f/n.to_f)	

	p "diff from PI"
	p (Math::PI - rs_pi).abs
	p (Math::PI - qrs_pi).abs
end

