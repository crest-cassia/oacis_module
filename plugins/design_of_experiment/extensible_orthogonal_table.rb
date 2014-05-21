require_relative 'orthogonal_table'
require_relative './controllers/orthogonal_controller'
require 'pry'

class ExtensibleOrthogonalTable

	def initialize(module_input_data=nil)
		@module_input_data = module_input_data
		@orthogonal_controller = OrthogonalController.new
	end

  # 
  def initial_regist_rows(rows)
    checked_rows = @orthogonal_controller.duplicate_check(rows)
    if !checked_rows[:new].empty?
      checked_rows[:new].each do |row|
        @orthogonal_controller.create(row)
      end
    else
    end

    return checked_rows
  end

	# 
  def generation_orthogonal_table(ps_block)

  	rows = ps_blocks_to_rows(ps_block)
  	checked_rows = @orthogonal_controller.duplicate_check(rows)
  	if !checked_rows[:new].empty?
  		checked_rows[:new].each do |row|
  			@orthogonal_controller.create(row)
  		end
  	else

  	end
  end

  # 
  def get_rows(ps_block)
    rows = ps_blocks_to_rows(ps_block)
    checked_rows = @orthogonal_controller.duplicate_check(rows)
    return checked_rows[:duplicate]
  end

  # 
  def is_alredy_block_include_range(range) # name, value
    condition = {"$or" => [] }
    range.each do |key, values|
    	values.each do |v|
    		condition["$or"] << {"row.#{key}.value" => v}
    	end
    end

    rows = @orthogonal_controller.find_rows(condition)
    
    if rows.count > 0
    	return rows.map { |r| r["row"]  }
    else
    	return []
    end
  end

  def is_alredy_block_include_range_hash(range_hash)
    and_condition = {"$and" => [] }
    range_hash.each do |name, range|
      or_condition = {"$or" => [] }
      range.each do |v|
        or_condition["$or"] << {"row.#{name}.value" => v}
      end
      and_condition["$and"] << or_condition
    end

    rows = @orthogonal_controller.find_rows(and_condition)

    if rows.count > 0
      return rows.map { |r| r["row"]  }
    else
      return []
    end
  end


  def inside_range_hash(ps_block, index)

    # check number of digit
    

    # update 
    # assignment variables to orthogonal table


    v_values = ps_block[:ps].map {|ps| ps[:v][index] }
    old_range = [v_values.min, v_values.max]
    one_third = old_range[0]*2 / 3 + old_range[1]   /3
    two_third = old_range[0]   / 3 + old_range[1]*2 /3
    # one_third = one_third.round(6) if one_third.is_a?(Float)
    # two_third = two_third.round(6) if two_third.is_a?(Float)
    new_range = []
    new_range << one_third.round(6) if one_third.is_a?(Float)
    new_range << two_third.round(6) if two_third.is_a?(Float)

    new_ranges = [
      [old_range.first, one_third], new_range, [two_third, old_range.last]
    ]


    old_rows = get_rows(ps_block)

    new_range_hash = ps_block_to_range_hash(ps_block)


# = test
binding.pry
    is_already_assigned_inside_range(ps_block[:keys][index], ps_block, old_range, new_range)


    new_range_hash[ps_block[:keys][index]] = new_range
    already_rows = is_alredy_block_include_range_hash(new_range_hash)
    new_rows = []
    if !already_rows.empty?
      tmp_rows = old_rows - already_rows
      tmp_rows.each{|hash|
        new_hash = Marshal.load(Marshal.dump(hash))
        new_hash[ps_block[:keys][index]]["bit"] = "1" + new_hash[ps_block[:keys][index]]["bit"]
        value = new_range - already_rows[0][ps_block[:keys][index]]["value"]
        new_hash[ps_block[:keys][index]]["value"] = value[0]
        new_rows << new_hash
      }
      new_rows
    else
      tmp_rows.each{|hash|
        new_hash = Marshal.load(Marshal.dump(hash))
        new_hash[ps_block[:keys][index]]["bit"] = "1" + new_hash[ps_block[:keys][index]]["bit"]

      }
    end

      binding.pry

# = test    



    new_ranges.each do |range|
      new_range_hash[ps_block[:keys][index]] = range
      already_rows = is_alredy_block_include_range_hash(new_range_hash)

      new_rows = []

      tmp_rows = old_rows - already_rows
      tmp_rows.each{|hash|
        new_hash = Marshal.load(Marshal.dump(hash))
        new_hash[ps_block[:keys][index]]["bit"] = "1" + new_hash[ps_block[:keys][index]]["bit"]
        value = range - [already_rows[0][ps_block[:keys][index]]["value"]]
        new_hash[ps_block[:keys][index]]["value"] = value[0]
        new_rows << new_hash
      }
      new_rows

      binding.pry
      extend_orthogonal_table(ps_block[:keys][index], new_ranges[1])

      # if update flag = true by checking digit number, 
      # then "all rows" are updated 

    end
    

    binding.pry


    old_row_set = []
    new_ranges.each do |r|
      old_rows = @xot.is_alredy_block_include_range({ps_block[:keys][index] => r})
      if !old_rows.empty?
        @xot.get_rows(ps_block)
        binding.pry
      end
    end

    range_hash
  end

  def bothside_range_hash(ps_block)
    
  end

	private
  # 
  def ps_blocks_to_rows(ps_block)
    rows = []
    param_names = ps_block[:keys].map{|k| k }
    ps_block[:ps].each do |ps|
    	row = {}
    	ps[:v].each_with_index do |value, idx|
    		row[param_names[idx]] = {"bit" => nil, "value" => value}
    	end
    	rows << row
    end
    rows
	end

  #
  def ps_block_to_range_hash(ps_block)

    range_hash = {}
    ps_block[:keys].each_with_index do |key, index|
      v_values = ps_block[:ps].map {|ps| ps[:v][index] }
      range_hash[key] = [v_values.min, v_values.max]
    end
    range_hash
  end

  # 
  def is_already_assigned_inside_range(name, ps_block, old_rage, new_range)
    corresponds = @orthogonal_controller.get_parameter_correspond(name).uniq
    param_defs = corresponds.map{|corr| corr["value"]}.uniq

    if 2 < param_defs.size
      if param_defs.find{|v| old_rage.min < v && v < old_rage.max}.nil?
        min_bit, max_bit = nil, nil

        if param_defs.include?(new_range.min)
          existed_parameter = corresponds.find{|corr| corr["value"]  == new_range.min}
          old_parameter = corresponds.find{|corr| corr["value"]  == old_rage.min}
          if existed_parameter["bit"][-1] != old_parameter["bit"][-1]
            min_bit = existed_parameter["bit"]
          end
        end

        if param_defs.include?(new_range.max)
          existed_parameter = corresponds.find{|corr| corr["value"]  == new_range.max}
          old_parameter = corresponds.find{|corr| corr["value"]  == old_rage.max}
          if existed_parameter["bit"][-1] != old_parameter["bit"][-1]
            max_bit = existed_parameter["bit"]
          end
        end

        if min_bit.nil? || max_bit.nil?
          # btwn_params = param_defs.select{|v| old_rage.min < v && v < old_rage.max}.sort
          btwn_corresponds = corresponds.select{|cor| old_rage.min < cor["value"] && cor["value"] < old_rage.max}
          min_corr, maxp = nil, nil
          abs = nil
          if min_bit.nil?
            old_min_bit = corresponds.find{|cor| cor["value"] = old_rage.min}
            lower_candidats = btwn_corresponds.select{|cor| old_min_bit[-1] != cor["bit"][-1] }
            # find near value
            lower_candidats.each{|cor|
              if abs.nil? || abs > (cor["value"] - old_rage.min).abs
                abs = (cor["value"] - old_rage.min).abs
                min_corr = cor
              end
            }
            min_bit = min_corr["bit"]
            new_range << min_corr["value"]
          end
          abs = nil
          if max_bit.nil?
            old_max_bit = corresponds.find{|cor| cor["value"] = old_rage.max}
            upper_candidats = btwn_corresponds.select{|cor| old_max_bit[-1] != cor["bit"][-1] }
            # find near value
            upper_candidats.each{|cor|
              if abs.nil? || abs > (cor["value"] - old_rage.max).abs
                abs = (cor["value"] - old_rage.max).abs
                max_cor = cor
              end
            }
            max_bit = max_cor["bit"]
            new_range << max_cor["value"]
          end


          if !min_bit.nil? && !max_bit.nil?
            new_range = []
          else
            new_range.sort!
          end
        end

        if (!min_bit.nil? && !max_bit.nil?)
          old_rows = get_rows(ps_block)
          condition = {"$or" => []}
          or_condition = {"$or" => [{"row.#{name}.bit" => min_bit}, {"row.#{name}.bit" => max_bit}]}
          and_condition = {"$and" => []}
          old_rows.each do |row|
            row.each do |name, corr|
              and_condition["$and"] << {"row.#{name}.bit" => corr["bit"]}
            end
          end
          and_condition << or_condition
          condition << and_condition
        end
        existed_rows = @orthogonal_controller.find_rows(condition)
        if existed_rows.count > 0
          existed_rows.each do |row|
            
          end
          binding.pry
        end
      end
    end


    ps_blocks = []

    return new_range, ps_blocks
  end

  # 
  def extend_orthogonal_table(name, new_variables)
    correspond = @orthogonal_controller.get_parameter_correspond(name)
    variables = correspond.map{|bit,value| value}.uniq
    additional_size = new_variables - variables
    old_digit_num = correspond[0]["bit"].size
    digit_num = Math.log2(variables.size + additional_size)
  end

	# # 
	# def check(rows)
	# 	@orthogonal_controller.duplicate_check(rows)
	# end

end

if __FILE__ == $0
	ps_block = {:keys=>["beta", "H"],
	:ps=>
  	[{:v=>[0.5, -0.1], :result=>nil},
   	{:v=>[0.5, 0.0], :result=>nil},
   	{:v=>[0.6, -0.1], :result=>nil},
   	{:v=>[0.6, 0.0], :result=>nil}],
 	:priority=>1.0,
 	:direction=>"outside"}

 	xot = ExtensibleOrthogonalTable.new
  rows = xot.generation_orthogonal_table(ps_block)

  # rows = [{"beta"=>{"bit"=>nil, "value"=>0.5}, "H"=>{"bit"=>nil, "value"=>-0.1}},
  #         {"beta"=>{"bit"=>nil, "value"=>0.5}, "H"=>{"bit"=>nil, "value"=>0.0}},
  #         {"beta"=>{"bit"=>nil, "value"=>0.6}, "H"=>{"bit"=>nil, "value"=>-0.1}},
  #         {"beta"=>{"bit"=>nil, "value"=>0.6}, "H"=>{"bit"=>nil, "value"=>0.0}}
  #       ]


	binding.pry
end