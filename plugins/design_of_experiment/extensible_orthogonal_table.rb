require_relative 'orthogonal_table'
require_relative './controllers/orthogonal_controller'
require 'pry'

class ExtensibleOrthogonalTable

  # 
	def initialize(module_input_data=nil)
		@module_input_data = module_input_data
		@orthogonal_controller = OrthogonalController.new
	end

  # 
  def initial_regist_rows(rows)
    checked_rows = @orthogonal_controller.duplicate_check(@module_input_data["_target"]["Simulator"], rows)
    if !checked_rows[:new].empty?
      checked_rows[:new].each do |row|
        @orthogonal_controller.create(@module_input_data["_target"]["Simulator"], row)
      end
    else
    end

    return checked_rows
  end

	# 
  def generation_orthogonal_table(ps_block)

  	rows = ps_blocks_to_rows(ps_block)
  	checked_rows = @orthogonal_controller.duplicate_check(@module_input_data["_target"]["Simulator"], rows)
  	if !checked_rows[:new].empty?
  		checked_rows[:new].each do |row|
  			@orthogonal_controller.create(@module_input_data["_target"]["Simulator"], row)
  		end
  	else

  	end
  end

  # 
  def get_rows(ps_block)
    rows = ps_blocks_to_rows(ps_block)
    checked_rows = @orthogonal_controller.duplicate_check(@module_input_data["_target"]["Simulator"], rows)
    return checked_rows[:duplicate]
  end

  # 
  def find_rows(name, range)
    condition = {"$or" => range.map{|v| {"row.#{name}.value" => v}} }
    rows = @orthogonal_controller.find_rows(@module_input_data["_target"]["Simulator"], condition)
    if rows.count > 0
      return rows.map { |r| r["row"]  }
    else
      return []
    end
  end

  # 
  def is_alredy_block_include_range_hash(range_hash)
    and_condition = {"$and" => [] }
    range_hash.each do |name, range|
      or_condition = {"$or" => [] }
      range.each do |v|
        or_condition["$or"] << {"row.#{name}.value" => v}
      end
      and_condition["$and"] << or_condition
    end

    rows = @orthogonal_controller.find_rows(@module_input_data["_target"]["Simulator"], and_condition)

    if rows.count > 0
      return rows.map { |r| r["row"]  }
    else
      return []
    end
  end

  # 
  def inside_ps_blocks(ps_block, index, priority=1.0)

    param_name = ps_block[:keys][index]

    v_values = ps_block[:ps].map {|ps| ps[:v][index] }
    old_range = [v_values.min, v_values.max]
    one_third = old_range[0]*2 / 3 + old_range[1]   /3
    two_third = old_range[0]   / 3 + old_range[1]*2 /3

    new_range = []
    new_range << one_third.round(6) if one_third.is_a?(Float)
    new_range << two_third.round(6) if two_third.is_a?(Float)
    new_ranges = []

    old_rows = get_rows(ps_block)

    corresponds = @orthogonal_controller.get_parameter_correspond(@module_input_data["_target"]["Simulator"], param_name)
    param_array = corresponds.map{|corr| corr["value"]}.uniq.compact
    existed_ps_blocks = []
    if 2 < param_array.size
      if !param_array.find{|v| old_range.min < v && v < old_range.max}.nil?
        min_bit, max_bit = nil, nil

        if param_array.include?(new_range.min)
          existed_parameter = corresponds.find{|corr| corr["value"]  == new_range.min}
          old_parameter = corresponds.find{|corr| corr["value"]  == old_range.min}
          if existed_parameter["bit"][-1] != old_parameter["bit"][-1]
            min_bit = existed_parameter["bit"]
          end
        end

        if param_array.include?(new_range.max)
          existed_parameter = corresponds.find{|corr| corr["value"]  == new_range.max}
          old_parameter = corresponds.find{|corr| corr["value"]  == old_range.max}
          if existed_parameter["bit"][-1] != old_parameter["bit"][-1]
            max_bit = existed_parameter["bit"]
          end
        end

        if min_bit.nil? || max_bit.nil?
          new_range = []
          # btwn_params = param_array.select{|v| old_range.min < v && v < old_range.max}.sort
          btwn_corresponds = corresponds.select{|cor| old_range.min < cor["value"] && cor["value"] < old_range.max}
          min_cor, max_cor = nil, nil
          abs = nil
          if min_bit.nil?

            old_min_bit = corresponds.find{|cor| cor["value"] = old_range.min}
            lower_candidats = btwn_corresponds.select{|cor| old_min_bit[-1] != cor["bit"][-1] }
            # find near value
            lower_candidats.each{|cor|
              if abs.nil? || abs > (cor["value"] - old_range.min).abs
                abs = (cor["value"] - old_range.min).abs
                min_cor = cor
              end
            }
            min_bit = min_cor["bit"]
            new_range << min_cor["value"]
          end
          abs = nil
          if max_bit.nil?
            old_max_bit = corresponds.find{|cor| cor["value"] = old_range.max}
            upper_candidats = btwn_corresponds.select{|cor| old_max_bit[-1] != cor["bit"][-1] }
            # find near value
            upper_candidats.each{|cor|
              if abs.nil? || abs > (cor["value"] - old_range.max).abs
                abs = (cor["value"] - old_range.max).abs
                max_cor = cor
              end
            }
            max_bit = max_cor["bit"]
            new_range << max_cor["value"]
          end
        end

        if (!min_bit.nil? && !max_bit.nil?)  # <- already assigned parameters are existed
          new_ranges = [  [old_range.min, new_range.min], 
                          new_range, 
                          [new_range.max, old_range.max]
                        ]
          # range_to_ps_block(old_rows, param_name, new_range, "inside", priority)
          new_ranges.each do |inside_range|
            if !inside_range.empty?
              new_ps_block = range_to_ps_block(old_rows, param_name, inside_range, "inside", priority)
              existed_ps_blocks << new_ps_block if !new_ps_block.empty?
            end
          end
          new_range = []
          new_ranges = []
        else
          new_range.sort!
          new_ranges = [  [old_range.min, new_range.min], 
                          new_range, 
                          [new_range.max, old_range.max]
                        ]
          update_orthogonal_table(corresponds, param_name, new_range, "inside")
        end
      else
        new_ranges = [ [old_range.min, new_range.min], 
                     new_range, 
                     [new_range.max, old_range.max]
                   ]
        update_orthogonal_table(corresponds, param_name, new_range, "inside")  
      end
    else
      new_ranges = [ [old_range.min, new_range.min], 
                     new_range, 
                     [new_range.max, old_range.max]
                   ]
      update_orthogonal_table(corresponds, param_name, new_range, "inside")
    end
    
    new_ps_blocks = []
    new_ranges.each do |inside_range|
      if !inside_range.empty?
        new_ps_block = range_to_ps_block(old_rows, param_name, inside_range, "inside", priority)
        new_ps_blocks << new_ps_block if !new_ps_block.empty?
      end
    end

    return new_ps_blocks + existed_ps_blocks
  end

  # 
  def outside_ps_blocks(ps_block, index, priority=1.0)
    param_name = ps_block[:keys][index]

    old_range = ps_block[:ps].map {|ps| ps[:v][index] }.uniq
    lower = old_range.min - @module_input_data["step_size"][ps_block[:keys][index]]
    upper = old_range.max + @module_input_data["step_size"][ps_block[:keys][index]]
    lower = lower.round(6) if lower.is_a?(Float)
    upper = upper.round(6) if upper.is_a?(Float)

    old_rows = get_rows(ps_block)
    corresponds = @orthogonal_controller.get_parameter_correspond(@module_input_data["_target"]["Simulator"], param_name)
    param_array = corresponds.map{|corr| corr["value"]}.uniq.compact

    if param_array.any?{|v| v < old_range.min}
      candidates = corresponds.select{|cor| cor["value"] < old_range.min }
      tmp_cor = corresponds.find{|cor| cor["value"] == old_range.min }
      candidates = candidates.select{|cor| cor["bit"][-1] != tmp_cor["bit"][-1]}

      lower = candidates.min_by{|cor| 
        (cor["value"] - (old_range.min - @module_input_data["step_size"][param_name])).abs }["value"]
      lower = candidates.max_by{|cor| cor["value"]}["value"] if lower.nil?
    elsif lower < @module_input_data["_managed_parameters"][index]["range"].min
      lower = @module_input_data["_managed_parameters"][index]["range"].min
    end

    if param_array.any?{|v| old_range.max < v}
      candidates = corresponds.select{|cor| old_range.max < cor["value"] }
      tmp_cor = corresponds.find{|cor| cor["value"] == old_range.max }
      candidates = candidates.select{|cor| cor["bit"][-1] != tmp_cor["bit"][-1]}

      upper = candidates.min_by{|cor| 
        (cor["value"] - (old_range.max + @module_input_data["step_size"][param_name])).abs }["value"]
      upper = candidates.min_by{|cor| cor["value"]}["value"] if upper.nil?
    elsif @module_input_data["_managed_parameters"][index]["range"].max < upper
      upper = @module_input_data["_managed_parameters"][index]["range"].max
    end

    new_range = [lower, upper]
    new_ranges = []


    existed_ps_blocks = []
    if 2 < param_array.size
      if param_array.include?(lower)
        min_bit = corresponds.find{|cor| cor["value"] == lower}["bit"]
        new_range.delete(lower)
      elsif !(near_lower = near_value(lower, param_array, param_name)).nil?
        min_bit = corresponds.find{|cor| cor["value"] == near_lower}["bit"]
        new_range.delete(lower)
        lower = near_lower
      end
      if param_array.include?(upper)
        max_bit = corresponds.find{|cor| cor["value"] == upper}["bit"]
        new_range.delete(upper)
      elsif !(near_upper = near_value(upper, param_array, param_name)).nil?
        max_bit = corresponds.find{|cor| cor["value"] == near_upper}["bit"]
        new_range.delete(upper)
        upper = near_upper
      end
      
      if !min_bit.nil?
        lower_range = [lower, old_range.min]
        new_ps_block = range_to_ps_block(old_rows, param_name, lower_range, "outside", priority)
        existed_ps_blocks << new_ps_block if !new_ps_block.empty?        
      else
        new_ranges << [lower, old_range.min]
      end

      if !max_bit.nil?
        upper_range = [old_range.max, upper]
        new_ps_block = range_to_ps_block(old_rows, param_name, upper_range, "outside", priority)
        existed_ps_blocks << new_ps_block if !new_ps_block.empty?     
      else
        new_ranges << [old_range.max, upper]
      end
    else
      new_ranges = [ [lower, old_range.min],
                      [old_range.max, upper]
                    ]
    end
    
    new_ps_blocks = []
    if !new_range.empty?
      update_orthogonal_table(corresponds, param_name, new_range, "outside")
      new_ranges.each do |outside_range|
        new_ps_block = range_to_ps_block(old_rows, param_name, outside_range, "outside", priority)        
        new_ps_blocks << new_ps_block if !new_ps_block.empty?
      end
    end

    return new_ps_blocks + existed_ps_blocks
  end

  # 
  def wide_ps_block(ps_block, prng, priority=1.0)
    edge = {}

    ps_block[:keys].each do |param_name|
      corresponds = @orthogonal_controller.get_parameter_correspond(@module_input_data["_target"]["Simulator"], param_name)
      edge[param_name] ||= []
      param_array = corresponds.map{|cor| cor["value"]}.uniq.compact
      if prng.rand < 0.5
        edge[param_name] << param_array.min
        edge[param_name] << param_array.sort[1]
      else
        edge[param_name] << param_array.sort[-2]
        edge[param_name] << param_array.max
      end
    end

    condition = {"$and" => []}

    edge.each do |k, arr|
      condition["$and"] << {"$or" => [{"row.#{k}.value" => arr.min}, {"row.#{k}.value" => arr.max}]}
    end
    ret = @orthogonal_controller.find_rows(@module_input_data["_target"]["Simulator"], condition)

    if ret.count != 0
      ret = ret.map{|r| r["row"]}
      new_ps_block = rows_to_ps_block(ret, "outside", priority)
      return new_ps_block
    else
      return {}
    end
  end

  def test_query
    @orthogonal_controller.test_query
    # @orthogonal_controller.get_parameter_correspond(name)
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
  def rows_to_ps_block(rows, direction, priority=1.0)
    ps_block = {}
    binding.pry if rows[0].nil?
    ps_block[:keys] = rows[0].map{|name, corr| name }
    ps_block[:ps] = []

    rows.each do |r|
      ps_v = r.map{|name, cor| cor["value"] }
      ps_block[:ps] << {v: ps_v, result: nil}
    end
    ps_block[:priority] = priority
    ps_block[:direction] = direction
    ps_block
  end

  # 
  def range_to_ps_block(old_rows, name, range, direction, priority=1.0)
    return [] if range.empty?

    condition = {"$and" => []}

    condition["$and"] << {"$or" => range.map{|v| {"row.#{name}.value" => v}} }

    h = {}
    old_rows.each{ |r|
      r.each{|k, cor|
        if k != name
          h[k] ||= []
          h[k] << cor["bit"]
        end
      }
    }
    h.each{|k,arr| arr.uniq!}
    h.each do |k, range|
      condition["$and"] << {"$or" => range.map{|v| {"row.#{k}.bit" => v}} }
    end
    new_rows = @orthogonal_controller.find_rows(@module_input_data["_target"]["Simulator"], condition).map{|r| r.row}
    binding.pry if new_rows.empty?
    return rows_to_ps_block(new_rows, direction, priority)
  end

  # 
  def update_orthogonal_table(corresponds, name, new_variables, direction)
    variables = corresponds.map{|cor| cor["value"]}.uniq
    old_digit_num = corresponds[0]["bit"].size
    digit_num = Math.log2(variables.size + new_variables.size).ceil

    if old_digit_num < digit_num # extend orthogonal table
      
      old_size = @orthogonal_controller.get_size(@module_input_data["_target"]["Simulator"])
      
      new_corresponds = update_correspond_bit_string(corresponds, digit_num, old_digit_num, old_size)
      
      @orthogonal_controller.add_copied_table(@module_input_data["_target"]["Simulator"], name)
    end

    assign_parameter_to_orthogonal(corresponds, name, new_variables, direction)
  end

  # 
  def update_correspond_bit_string(corresponds, digit_num, old_digit_num, old_level)
    old_bit_str = "%0"+old_digit_num.to_s+"b"
    new_bit_str = "%0"+digit_num.to_s+"b"
    for i in 0...(2**old_digit_num)
      update_corr = corresponds.find{|cor| cor["bit"] == old_bit_str%i }
      if !update_corr.nil?
        corresponds.delete(update_corr)
        update_corr["bit"] = new_bit_str%i
        corresponds.push(update_corr)
      end
    end
    return corresponds
  end

  # 
  def assign_parameter_to_orthogonal(corresponds, name, new_param, direction)
    min_bit = nil
    h = {}
    case direction
    when "inside"
      digit_num_of_minus_side = corresponds.select{|cor|
        cor["value"] < new_param.min
      }.max_by{|cor| cor["value"]}["bit"]
      if digit_num_of_minus_side[-1] == "0"
        count = 1
        new_param.each{|v| 
          h[v] = (count % 2).to_s
          count += 1
        }
      else
        count = 0
        new_param.each{|v| 
          h[v] = (count % 2).to_s
          count += 1
        }
      end
    when "outside"
      if new_param.size == 2
        right_digit = corresponds.max_by { |cor| 
          cor["value"] < new_param.max ? cor["value"] : -1 
        }["bit"]
        left_digit = corresponds.min_by { |cor| 
          cor["value"] > new_param.min ? cor["value"] : corresponds.size
        }["bit"]
        if right_digit[-1] == "0"
          h[new_param.max] = "1"
        else
          h[new_param.max] = "0"
        end
        if left_digit[-1] == "0"
          h[new_param.min] = "1"
        else
          h[new_param.min] = "0"
        end
      else # new_param.size == 1
        # if param_array.max < new_param[0] #upper
        corresponds_max = corresponds.max_by{|cor| cor["value"]}
        corresponds_min = corresponds.min_by{|cor| cor["value"]}
        if corresponds_max["value"] < new_param[0] #upper
          right_digit_of_max = corresponds_max["bit"]
          if right_digit_of_max[-1] == "0"
            h[new_param[0]] = "1"
          else
            h[new_param[0]] = "0"
          end
        elsif corresponds_min["value"] > new_param[0] #lower
          right_digit_of_min = corresponds_min["bit"]
          if right_digit_of_min[-1] == "0"
            h[new_param[0]] = "1"
          else
            h[new_param[0]] = "0"
          end
        else # error
          raise "parameter creation is error"
          # p add_parameters
          # pp @parameters[name]
        end
      end
    else
      raise "new parameter could not be assigned to bit on orthogonal table"
    end

    additional_cor = link_parameter(corresponds, h)
    @orthogonal_controller.assign_parameter_to_table(@module_input_data["_target"]["Simulator"], name, additional_cor)
  end

  # 
  def link_parameter(corresponds, paramDefs_hash)
    added_corresponds = []
    total_size = corresponds.size + paramDefs_hash.size
    digit_num = Math.log2(total_size).ceil
    old_level = corresponds.size
    bit_i = 0
    while bit_i < total_size
      bit = ("%0" + digit_num.to_s + "b") % bit_i
      if corresponds.find{|cor| cor["bit"] == bit}.nil?
        if paramDefs_hash.has_value?(bit[-1])
          param = paramDefs_hash.key(bit[-1])
          add_cor = {}
          add_cor["bit"] = bit
          add_cor["value"] = param
          paramDefs_hash.delete(param)
          corresponds << add_cor
          added_corresponds << add_cor
        else
          total_size += 1
        end 
      end
      bit_i += 1
    end
    return added_corresponds
  end

  # 
  def near_value(value, paramDefs, name)
    ret = nil
    paramDefs.each{|v|
      if ((value - @module_input_data["step_size"][name]) < v) && (v < (value + @module_input_data["step_size"][name]))
        ret = v
      end
    }
    return ret
  end

end

# for debug
if __FILE__ == $0

  cors = [{"bit"=>"00","value"=>0},
          {"bit"=>"01","value"=>1},
          {"bit"=>"10","value"=>2},
          {"bit"=>"11","value"=>3}
        ]
binding.pry

  xot = ExtensibleOrthogonalTable.new
  xot.test_query

  exit(0)

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
  arr = [0, 2]
  cors = [{"bit"=>"00","value"=>0},
          {"bit"=>"01","value"=>1},
          {"bit"=>"10","value"=>2},
          {"bit"=>"11","value"=>3}
         ]

end