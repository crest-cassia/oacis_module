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


  def find_rows(name, range)
    condition = {"$or" => range.map{|v| {"row.#{name}.value" => v}} }
    rows = @orthogonal_controller.find_rows(condition)
    if rows.count > 0
      return rows.map { |r| r["row"]  }
    else
      return []
    end
  end

  #  == unused ? ===
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


  # 
  def inside_ps_blocks(ps_block, index)

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

    corresponds = @orthogonal_controller.get_parameter_correspond(param_name).uniq
    param_defs = corresponds.map{|corr| corr["value"]}.uniq
    existed_ps_blocks = []
    if 2 < param_defs.size
      if param_defs.find{|v| old_range.min < v && v < old_range.max}.nil?
        min_bit, max_bit = nil, nil

        if param_defs.include?(new_range.min)
          existed_parameter = corresponds.find{|corr| corr["value"]  == new_range.min}
          old_parameter = corresponds.find{|corr| corr["value"]  == old_range.min}
          if existed_parameter["bit"][-1] != old_parameter["bit"][-1]
            min_bit = existed_parameter["bit"]
          end
        end

        if param_defs.include?(new_range.max)
          existed_parameter = corresponds.find{|corr| corr["value"]  == new_range.max}
          old_parameter = corresponds.find{|corr| corr["value"]  == old_range.max}
          if existed_parameter["bit"][-1] != old_parameter["bit"][-1]
            max_bit = existed_parameter["bit"]
          end
        end

        if min_bit.nil? || max_bit.nil?
          new_range = []
          # btwn_params = param_defs.select{|v| old_range.min < v && v < old_range.max}.sort
          btwn_corresponds = corresponds.select{|cor| old_range.min < cor["value"] && cor["value"] < old_range.max}
          min_corr, maxp = nil, nil
          abs = nil
          if min_bit.nil?
            old_min_bit = corresponds.find{|cor| cor["value"] = old_range.min}
            lower_candidats = btwn_corresponds.select{|cor| old_min_bit[-1] != cor["bit"][-1] }
            # find near value
            lower_candidats.each{|cor|
              if abs.nil? || abs > (cor["value"] - old_range.min).abs
                abs = (cor["value"] - old_range.min).abs
                min_corr = cor
              end
            }
            min_bit = min_corr["bit"]
            new_range << min_corr["value"]
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
          new_range = []
          new_ranges = []
          # old_rows = get_rows(ps_block)
          condition = {"$or" => []}
          or_condition = {"$or" => [{"row.#{param_name}.bit" => min_bit}, {"row.#{param_name}.bit" => max_bit}]}
          and_condition = {"$and" => []}
          old_rows.each do |row|
            row.each do |key, corr|
              and_condition["$and"] << {"row.#{key}.bit" => corr["bit"]}
            end
          end
          and_condition << or_condition
          condition << and_condition
          existed_rows = @orthogonal_controller.find_rows(condition)

          if existed_rows.count > 0
            existed_ps_blocks << rows_to_ps_block(existed_rows, ps_block[:direction], ps_block[:priority])
            ps_blocks = [{}, {}] # generate template
            ps_blocks.each do |ps_hash|
              ps_block[:keys] = rows[0]["row"].map{|key, corr| key }  
              ps_block[:ps] = []
              ps_block[:priority] = priority
              ps_block[:direction] = "inside"
            end
                
            existed_rows.each do |row|
              if row["row"][param_name]["bit"][-1] == "0"
                ps_blocks[0][:ps] << row["row"].map{|key, cor| cor["value"]}
              elsif row["row"][param_name]["bit"][-1] == "1"
                ps_blocks[1][:ps] << row["row"].map{|key, cor| cor["value"]}
              end
            end
            old_rows.each do |row|
              if row["row"][param_name]["bit"][-1] == "1"
                ps_blocks[0][:ps] << row["row"].map{|key, cor| cor["value"]}
              elsif row["row"][param_name]["bit"][-1] == "0"
                ps_blocks[1][:ps] << row["row"].map{|key, cor| cor["value"]}
              end
            end
            existed_ps_blocks += ps_blocks
          end
        else
          new_range.sort!
          new_ranges = [  [old_range.first, new_range.max], 
                          new_range, 
                          [new_range.min, old_range.last]
                        ]
          update_orthogonal_table(param_name, new_range, "inside")
        end
      end
    else
      new_ranges = [ [old_range.first, new_range.max], 
                     new_range, 
                     [new_range.min, old_range.last]
                   ]
    end
    
    new_ps_blocks = []
    new_ranges.each do |inside_range|
      if !inside_range.empty?
        new_ps_blocks << inside_range_to_ps_block(old_rows, param_name, inside_range)
      end
    end
binding.pry
    return new_ps_blocks + existed_ps_blocks
  end

  # 
  def outside_ps_block(ps_block, index)
    param_name = ps_block[:keys][index]

    v_values = ps_block[:ps].map {|ps| ps[:v][index] }
    old_range = [v_values.min, v_values.max]
    lower = range[0] - @module_input_data["step_size"][ps_block[:keys][index]]
    upper = range[1] + @module_input_data["step_size"][ps_block[:keys][index]]
    lower = lower.round(6) if lower.is_a?(Float)
    upper = upper.round(6) if upper.is_a?(Float)

    old_rows = get_rows(ps_block)
    corresponds = @orthogonal_controller.get_parameter_correspond(param_name).uniq
    param_defs = corresponds.map{|corr| corr["value"]}.uniq


    if param_defs.any?{|v| v < old_range.min}
      candidates = corresponds.select{|cor| cor["value"] < old_range.min }
      tmp_cor = corresponds.find{|cor| cor["value"] == old_range.min }
      candidates = candidates.select{|cor| cor["bit"][-1] != tmp_cor["bit"][-1]}

      lower = candidates.min_by{|v| 
        (v - (old_range.min - @module_input_data["step_size"][param_name])).abs }
      lower = candidates.max if lower.nil?
    elsif lower < @module_input_data["_managed_parameters"][index]["range"].min
      lower = @module_input_data["_managed_parameters"][index]["range"].min
    else
      lower = lower - @module_input_data["step_size"][param_name]
      lower = lower.round(6)if new_lower.class == Float
    end

    if param_defs.any?{|v| old_range.min < v}
      candidates = corresponds.select{|cor| old_range.max < cor["value"] }
      tmp_cor = corresponds.find{|cor| cor["value"] == old_range.max }
      candidates = candidates.select{|cor| cor["bit"][-1] != tmp_cor["bit"][-1]}

      upper = candidates.min_by{|v| 
        (v - (old_range.max + @module_input_data["step_size"][param_name])).abs }
      upper = candidates.min if upper.nil?
    elsif upper < @module_input_data["_managed_parameters"][index]["range"].max
      upper = @module_input_data["_managed_parameters"][index]["range"].max
    else
      upper = upper + @module_input_data["step_size"][param_name]
      upper = upper.round(6)if new_lower.class == Float
    end

    new_range = [lower, upper]
    new_ranges = []
    # ranges = [ [lower, old_range.min], [old_range.max, upper] ]
    # lower_range = [lower, old_range.min]
    # upper_range = [old_range.max, upper]


    existed_ps_blocks = []
    if 2 < param_defs.size
      # if param_defs.include?(new_array.min) ||
      #   !(tmp = near_value(new_array.min, param_defs, name, definition)).nil?
      #   min_bit = corresponds.key(new_array.min)
      #   new_array.delete(new_array.min)
      # end
      # if param_defs.include?(new_array.max) ||
      #   !(tmp = near_value(new_array.max, param_defs, name, definition)).nil?
      #   max_bit = parameters[name][:correspond].key(new_array.max)
      #   new_array.delete(new_array.max)
      # end
      if param_defs.include?(lower)
        min_bit = corresponds.find{|cor| cor["value"] == lower}
        new_range.delete(lower)
        # lower_range.clear
      elsif !(near_lower = near_value(lower, param_defs, param_name)).nil?
        min_bit = corresponds.find{|cor| cor["value"] == near_lower}
        new_range.delete(lower)
        # lower_range.clear
      end
      if param_defs.include?(upper)
        max_bit = corresponds.find{|cor| cor["value"] == upper}
        new_range.delete(upper)
        # upper_range.clear
      elsif !(near_upper = near_value(upper, param_defs, param_name)).nil?
        max_bit = corresponds.find{|cor| cor["value"] == near_upper}
        new_range.delete(upper)
        # upper_range.clear
      end
      
      # if !min_bit.nil?
      #   pmin_bit = parameters[name][:correspond].key(param.min)
      #   condition = [:or]
      #   orCond = [:or, [:eq, [:field, name], min_bit], [:eq, [:field, name], pmin_bit]]
      #   orthogonal_rows.each{|row|
      #     andCond = [:and]
      #     row.each{ |k, v|
      #       if k != "id" and k != "run" and k != name and !v.nil?
      #         andCond.push([:eq, [:field, k], v])
      #       end
      #     }
      #     andCond.push(orCond)
      #     condition.push(andCond)
      #   }
      #   exist_area = sql_connector.read_record(:orthogonal, condition) # nil check is easier maybe
      #   new_area.push(exist_area.map{|r| r["id"]})
      # end
      if !min_bit.nil?
        # pmin_cor = corresponds.find{|cor| cor["value"] == old_range.min}
        # condition = {"row.#{param_name}.value" => old_range.min}
        # rows = @orthogonal_controller.find_rows(condition)
        # old_lower_bit = corresponds.find{|cor| cor["value"] == old_range.min}["bit"]
        condition = {"$or" => []}
        or_condition = {"$or" => [{"row.#{param_name}.value" => min_bit}, {"row.#{param_name}.value" => old_range.min}]}#{"row.#{param_name}.bit" => old_lower_bit}]}
        and_condition = {"$and" => []}
        old_rows.each do |row|
          row.each do |key, corr|
            if key != param_name
              and_condition["$and"] << {"row.#{key}.bit" => corr["bit"]}
            end
          end
        end
        and_condition << or_condition
        condition << and_condition
        lower_rows = @orthogonal_controller.find_rows(condition)
        existed_ps_blocks << rows_to_ps_block(lower_rows, ps_block[:direction], ps_block[:priority])
      else
        new_ranges << [lower, old_range.min]
      end

      # if !max_bit.nil?
      #   pmax_bit = parameters[name][:correspond].key(param.max)
      #   condition = [:or]
      #   orCond = [:or, [:eq, [:field, name], max_bit], [:eq, [:field, name], pmax_bit]]
      #   orthogonal_rows.each{|row|
      #     andCond = [:and]
      #     row.each{ |k, v|
      #       if k != "id" and k != "run" and k != name and !v.nil?
      #         andCond.push([:eq, [:field, k], v])
      #       end
      #     }
      #     andCond.push(orCond)
      #     condition.push(andCond)
      #   }
      #   exist_area = sql_connector.read_record(:orthogonal, condition) # nil check is easier maybe
      #   new_area.push(exist_area.map{|r| r["id"]})
      # end
      if !max_bit.nil?
        condition = {"$or" => []}
        or_condition = {"$or" => [{"row.#{param_name}.value" => max_bit}, {"row.#{param_name}.value" => old_range.max}]}#{"row.#{param_name}.bit" => old_lower_bit}]}
        and_condition = {"$and" => []}
        old_rows.each do |row|
          row.each do |key, corr|
            if key != param_name
              and_condition["$and"] << {"row.#{key}.bit" => corr["bit"]}
            end
          end
        end
        and_condition << or_condition
        condition << and_condition
        upper_rows = @orthogonal_controller.find_rows(condition)
        existed_ps_blocks << rows_to_ps_block(upper_rows, ps_block[:direction], ps_block[:priority])
      else
        new_ranges << [old_range.max, upper]
      end
    end
    
    new_ps_blocks = []
    if !new_range.empty?
      update_orthogonal_table(param_name, new_range, "outside")
      new_ranges.each do |outside_range|
        new_ps_blocks << outside_range_to_ps_block(old_rows, param_name, outside_range)
      end
    end

binding.pry
    return new_ps_blocks + existed_ps_blocks
  end

  def test_query
    @orthogonal_controller.test_query
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
    ps_block[:keys] = rows[0]["row"].map{|name, corr| name }
    ps_block[:ps] = []

    rows.each do |r|
      ps_v = r["row"].map{|name, cor| cor["value"] }
      ps_block[:ps] << {v: ps_v, result: nil}
    end
    ps_block[:priority] = priority
    ps_block[:direction] = direction
    ps_block
  end

  # new ranges have been assigned
  def inside_range_to_ps_block(old_rows, name, inside_range)
    return [] if inside_range.empty?
    
    # orCond = [:or]
    # new_param[:param][:paramDefs].each{|v|
    #   bit = parameter[:correspond].key(v)
    #   new_bits.push(bit)
    #   orCond.push([:eq, [:field, new_param[:param][:name]], bit])
    # }

    # condition = [:or]
    # old_rows.each {|r|
    #   andCond = [:and]
    #   r.each{|k, v|
    #     if k != "id" and k != "run" and k != new_param[:param][:name]
    #       andCond.push([:eq, [:field, k], v])
    #     end
    #   }
    #   andCond.push(orCond)
    #   condition.push(andCond)
    # }
    # new_rows = sql_connector.read_record(:orthogonal, condition)
    new_rows = find_rows(name, inside_range)

    
=begin
    old_lower_value_rows = []
    old_upper_value_rows = []
    old_lower_value = nil
    old_upper_value = nil
    old_lower_bit = nil
    old_upper_bit = nil
    old_rows.each{ |row|
      if old_lower_value.nil? # old lower parameter
        # old_lower_value_rows.push(row["id"])
        # old_lower_value = parameter[:correspond][row[new_param[:param][:name]]]
        # old_lower_bit = row[new_param[:param][:name]]
        old_lower_value_rows.push(row["_id"])
        old_lower_value = row["row"][name]["value"]
        old_lower_bit = row["row"][name]["bit"]
      else
        # if parameter[:correspond][row[new_param[:param][:name]]] < old_lower_value
        #   old_lower_value_rows.clear
        #   old_lower_value_rows.push(row["id"])
        #   old_lower_value = parameter[:correspond][row[new_param[:param][:name]]]
        #   old_lower_bit = row[new_param[:param][:name]]
        # elsif parameter[:correspond][row[new_param[:param][:name]]] == old_lower_value
        #   old_lower_value_rows.push(row["id"])
        # end
        if row["row"][name]["value"] < old_lower_value
          old_lower_value_rows.clear
          old_lower_value_rows.push(row["_id"])
          old_lower_value = row["row"][name]["value"]
          old_lower_bit = row["row"][name]["bit"]
        elsif row["row"][name]["value"] == old_lower_value
          old_lower_value_rows.push(row["_id"])
        end
      end
      
      if old_upper_value.nil? # old upper parameter
        # old_upper_value_rows.push(row["id"])
        # old_upper_value = parameter[:correspond][row[new_param[:param][:name]]]
        # old_upper_bit = row[new_param[:param][:name]]
        old_upper_value_rows.push(row["_id"])
        old_upper_value = row["row"][name]["value"]
        old_upper_bit = row["row"][name]["bit"]
      else
        # if old_upper_value < parameter[:correspond][row[new_param[:param][:name]]]
        #   old_upper_value_rows.clear
        #   old_upper_value_rows.push(row["id"])
        #   old_upper_value = parameter[:correspond][row[new_param[:param][:name]]]
        #   old_upper_bit = row[new_param[:param][:name]]
        # elsif old_upper_value == parameter[:correspond][row[new_param[:param][:name]]]
        #   old_upper_value_rows.push(row["id"])
        # end
        if old_upper_value < row["row"][name]["value"]
          old_upper_value_rows.clear
          old_upper_value_rows.push(row["_id"])
          old_upper_value = row["row"][name]["value"]
          old_upper_bit = row["row"][name]["bit"]
        elsif row["row"][name]["value"] == old_upper_value
          old_upper_value_rows.push(row["_id"])
        end
      end
    }

    new_lower_value_rows = []
    new_upper_value_rows = []
    new_lower_value = nil
    new_upper_value = nil
    new_lower_bit = nil
    new_upper_bit = nil
    new_rows.each{ |row|
      if new_lower_value.nil? # new lower parameter
        # new_lower_value_rows.push(row["id"])
        # new_lower_value = parameter[:correspond][row[new_param[:param][:name]]]
        # new_lower_bit = row[new_param[:param][:name]]
        new_lower_value_rows.push(row["_id"])
        new_lower_value = row["row"][name]["value"]
        new_lower_bit = row["row"][name]["bit"]
      else
        # if parameter[:correspond][row[new_param[:param][:name]]] < new_lower_value
        #   new_lower_value_rows.clear
        #   new_lower_value_rows.push(row["id"])
        #   new_lower_value = parameter[:correspond][row[new_param[:param][:name]]]
        #   new_lower_bit = row[new_param[:param][:name]]
        # elsif parameter[:correspond][row[new_param[:param][:name]]] == new_lower_value
        #   new_lower_value_rows.push(row["id"])
        # end
        if row["row"][name]["value"] < new_lower_value
          new_lower_value_rows.clear
          new_lower_value_rows.push(row["_id"])
          new_lower_value = row["row"][name]["value"]
          new_lower_bit = row["row"][name]["bit"]
        elsif row["row"][name]["value"] == new_lower_value
          new_lower_value_rows.push(row["_id"])
        end
      end
      
      if new_upper_value.nil? # new upper parameter
        # new_upper_value_rows.push(row["id"])
        # new_upper_value = parameter[:correspond][row[new_param[:param][:name]]]
        # new_upper_bit = row[new_param[:param][:name]]
        new_upper_value_rows.push(row["_id"])
        new_upper_value = row["row"][name]["value"]
        new_upper_bit = row["row"][name]["bit"]
      else
        # if new_upper_value < parameter[:correspond][row[new_param[:param][:name]]]
        #   new_upper_value_rows.clear
        #   new_upper_value_rows.push(row["id"])
        #   new_upper_value = parameter[:correspond][row[new_param[:param][:name]]]
        #   new_upper_bit = row[new_param[:param][:name]]
        # elsif new_upper_value == parameter[:correspond][row[new_param[:param][:name]]]
        #   new_upper_value_rows.push(row["id"])
        # end
        if new_upper_value < row["row"][name]["value"]
          new_upper_value_rows.clear
          new_upper_value_rows.push(row["_id"])
          new_upper_value = row["row"][name]["value"]
          new_upper_bit = row["row"][name]["bit"]
        elsif row["row"][name]["value"] == old_upper_value
          new_upper_value_rows.push(row["_id"])
        end
      end
    }
=end
    
    old_lu_rows, new_lu_rows = get_lower_upper_rows(name, old_rows, new_rows)
    
    # generated_area = []
    # # (new_lower, new_upper)
    # generated_area.push(new_rows.map{ |r| r["id"] })
    # # between (old_lower, new_lower) in area
    # generated_area.push(old_lower_value_rows + new_lower_value_rows)
    # # between (old_upper, new_upper) in area
    # generated_area.push(old_upper_value_rows + new_upper_value_rows)
    
    new_ps_blocks = []
    new_ps_blocks << rows_to_ps_block(new_rows)
    new_ps_blocks << rows_to_ps_block(old_lu_rows[0] + new_lu_rows[0])
    new_ps_blocks << rows_to_ps_block(new_lu_rows[1] + old_lu_rows[1])

    return new_ps_blocks
  end

  # 
  def outside_range_to_ps_block(old_rows, name, outside_range)
    return [] if outside_range.empty?

    new_rows = find_rows(name, outside_range)
    old_lu_rows, new_lu_rows = get_lower_upper_rows(name, old_rows, new_rows)

    new_ps_blocks = []
    new_ps_blocks << rows_to_ps_block(new_lu_rows[0] + old_lu_rows[0])
    new_ps_blocks << rows_to_ps_block(old_lu_rows[1] + new_lu_rows[1])

    return new_ps_blocks
  end

  # 
  def get_lower_upper_rows(name, old_rows, new_rows)

    old_lower_value_rows = []
    old_upper_value_rows = []
    old_lower_value = nil
    old_upper_value = nil
    old_lower_bit = nil
    old_upper_bit = nil
    old_rows.each{ |row|
      if old_lower_value.nil? # old lower parameter
        # old_lower_value_rows.push(row["id"])
        # old_lower_value = parameter[:correspond][row[new_param[:param][:name]]]
        # old_lower_bit = row[new_param[:param][:name]]
        old_lower_value_rows.push(row)
        old_lower_value = row[name]["value"]
        old_lower_bit = row[name]["bit"]
      else
        # if parameter[:correspond][row[new_param[:param][:name]]] < old_lower_value
        #   old_lower_value_rows.clear
        #   old_lower_value_rows.push(row["id"])
        #   old_lower_value = parameter[:correspond][row[new_param[:param][:name]]]
        #   old_lower_bit = row[new_param[:param][:name]]
        # elsif parameter[:correspond][row[new_param[:param][:name]]] == old_lower_value
        #   old_lower_value_rows.push(row["id"])
        # end
        if row[name]["value"] < old_lower_value
          old_lower_value_rows.clear
          old_lower_value_rows.push(row)
          old_lower_value = row[name]["value"]
          old_lower_bit = row[name]["bit"]
        elsif row[name]["value"] == old_lower_value
          old_lower_value_rows.push(row)
        end
      end
      
      if old_upper_value.nil? # old upper parameter
        # old_upper_value_rows.push(row["id"])
        # old_upper_value = parameter[:correspond][row[new_param[:param][:name]]]
        # old_upper_bit = row[new_param[:param][:name]]
        old_upper_value_rows.push(row)
        old_upper_value = row[name]["value"]
        old_upper_bit = row[name]["bit"]
      else
        # if old_upper_value < parameter[:correspond][row[new_param[:param][:name]]]
        #   old_upper_value_rows.clear
        #   old_upper_value_rows.push(row["id"])
        #   old_upper_value = parameter[:correspond][row[new_param[:param][:name]]]
        #   old_upper_bit = row[new_param[:param][:name]]
        # elsif old_upper_value == parameter[:correspond][row[new_param[:param][:name]]]
        #   old_upper_value_rows.push(row["id"])
        # end
        if old_upper_value < row[name]["value"]
          old_upper_value_rows.clear
          old_upper_value_rows.push(row)
          old_upper_value = row[name]["value"]
          old_upper_bit = row[name]["bit"]
        elsif row[name]["value"] == old_upper_value
          old_upper_value_rows.push(row)
        end
      end
    }

    new_lower_value_rows = []
    new_upper_value_rows = []
    new_lower_value = nil
    new_upper_value = nil
    new_lower_bit = nil
    new_upper_bit = nil
    new_rows.each{ |row|
      if new_lower_value.nil? # new lower parameter
        # new_lower_value_rows.push(row["id"])
        # new_lower_value = parameter[:correspond][row[new_param[:param][:name]]]
        # new_lower_bit = row[new_param[:param][:name]]
        new_lower_value_rows.push(row)
        new_lower_value = row[name]["value"]
        new_lower_bit = row[name]["bit"]
      else
        # if parameter[:correspond][row[new_param[:param][:name]]] < new_lower_value
        #   new_lower_value_rows.clear
        #   new_lower_value_rows.push(row["id"])
        #   new_lower_value = parameter[:correspond][row[new_param[:param][:name]]]
        #   new_lower_bit = row[new_param[:param][:name]]
        # elsif parameter[:correspond][row[new_param[:param][:name]]] == new_lower_value
        #   new_lower_value_rows.push(row["id"])
        # end
        if row[name]["value"] < new_lower_value
          new_lower_value_rows.clear
          new_lower_value_rows.push(row)
          new_lower_value = row[name]["value"]
          new_lower_bit = row[name]["bit"]
        elsif row[name]["value"] == new_lower_value
          new_lower_value_rows.push(row)
        end
      end
      
      if new_upper_value.nil? # new upper parameter
        # new_upper_value_rows.push(row["id"])
        # new_upper_value = parameter[:correspond][row[new_param[:param][:name]]]
        # new_upper_bit = row[new_param[:param][:name]]
        new_upper_value_rows.push(row)
        new_upper_value = row[name]["value"]
        new_upper_bit = row[name]["bit"]
      else
        # if new_upper_value < parameter[:correspond][row[new_param[:param][:name]]]
        #   new_upper_value_rows.clear
        #   new_upper_value_rows.push(row["id"])
        #   new_upper_value = parameter[:correspond][row[new_param[:param][:name]]]
        #   new_upper_bit = row[new_param[:param][:name]]
        # elsif new_upper_value == parameter[:correspond][row[new_param[:param][:name]]]
        #   new_upper_value_rows.push(row["id"])
        # end
        if new_upper_value < row[name]["value"]
          new_upper_value_rows.clear
          new_upper_value_rows.push(row)
          new_upper_value = row[name]["value"]
          new_upper_bit = row[name]["bit"]
        elsif row[name]["value"] == old_upper_value
          new_upper_value_rows.push(row)
        end
      end
    }

    return [[old_lower_value_rows, old_upper_value_rows], [new_lower_value_rows, new_upper_value_rows]]
  end

  # 
  def update_orthogonal_table(name, new_variables, direction)
    correspond = @orthogonal_controller.get_parameter_correspond(name)
    variables = correspond.map{|bit, value| value}.uniq
    additional_size = new_variables - variables
    old_digit_num = correspond[0]["bit"].size
    digit_num = Math.log2(variables.size + additional_size)

    if old_digit_num < digit_num # extend orthogonal table
      
      old_size = @orthogonal_controller.get_size
      
      new_correspond = update_correspond_bit_string(correspond, digit_num, old_digit_num, old_size)
      
      @orthogonal_controller.add_copied_table(name)
    end

    assign_parameter_to_orthogonal(correspond, name, new_variables, direction)
    
binding.pry
  end

  # 
  def update_correspond_bit_string(correspond, digit_num, old_digit_num, old_level)
    old_bit_str = "%0"+old_digit_num.to_s+"b"
    new_bit_str = "%0"+digit_num.to_s+"b"
    # for i in 0...old_level
    for i in 0...(2**old_digit_num)
      update_corr = correspond.find{|cor| cor["bit"] == old_bit_str%i }
      correspond.delete(update_corr)
      update_corr["bit"] = new_bit_str%i
      corresponds.push(update_corr)
    end
    return correspond
  end

  # 
  def assign_parameter_to_orthogonal(correspond, name, new_param, direction)
    min_bit = nil
    h = {}
    case direction
    when "inside"
      digit_num_of_minus_side = correspond.select{|cor|
        cor["value"] < new_param.min
      }.max_by{|cor| cor["value"]}["bit"]
      # digit_num_of_minus_side = digit_num_of_minus_side["bit"]
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
        right_digit = correspond.max_by { |cor| 
          cor["value"] < new_param.max ? cor["value"] : -1 
        }["bit"]
        left_digit = correspond.min_by { |item| 
          cor["value"] > new_param.min ? cor["value"] : correspond.size
        }["bit"]
        if right_digit[-1] == "0" # [right_digit.size-1]
          h[new_param.max] = "1"
        else
          h[new_param.max] = "0"
        end
        if left_digit[-1] == "0" # [right_digit.size-1]
          h[new_param.min] = "1"
        else
          h[new_param.min] = "0"
        end
      else # new_param.size == 1
        # if param_defs.max < new_param[0] #upper
        correspond_max = correspond.max_by{|cor| cor["value"]}
        correspond_min = correspond.min_by{|cor| cor["value"]}
        if correspond_max["value"] < new_param[0] #upper
          right_digit_of_max = correspond_max["bit"]
          if right_digit_of_max[-1] == "0"
            h[new_param[0]] = "1"
          else
            h[new_param[0]] = "0"
          end
        elsif correspond_min > new_param[0] #lower
          right_digit_of_min = correspond_min["bit"]
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

    # old_level = correspond.size
    # param_defs += add_parameters
    additional_cor = link_parameter(name, h)
    @orthogonal_controller.assign_parameter_to_table(name, additional_cor)
binding.pry
  end

  # 
  def link_parameter(correspond, paramDefs_hash)
    added_corresponds = {}
    total_size = correspond.size + paramDefs_hash.size
    digit_num = log2(total_size).ceil
    old_level = correspond.size
    bit_i = 0
    while bit_i < total_size
      bit = ("%0" + digit_num.to_s + "b") % bit_i
      # if !@parameters[name][:correspond].key?(bit)
      if corresponds.find{|cor| cor["bit"] == bit}.nil?
        if paramDefs_hash.has_value?(bit[-1])
          param = paramDefs_hash.key(bit[-1])
          corresponds["bit"] = param
          added_corresponds["bit"] = param
          paramDefs_hash.delete(param)
        else
          total_size += 1
          # debug("#{paramDefs_hash}, top_count: #{total_size}")
          # debug("bit:#{bit}, last_str:#{bit[-1]}")
        end 
      end
      bit_i += 1
    end
    # if param_defs.size != @parameters[name][:correspond].size
    #   raise "no assignment parameter: 
    #     defs_L:#{param_defs.size}, 
    #     corr_L:#{@parameters[name][:correspond].size}"
    #   # binding.pry
    # end

    return added_corresponds
  end

  # 
  def near_value(value, paramDefs, name)
    ret = nil
    # binding.pry if value.nil?
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