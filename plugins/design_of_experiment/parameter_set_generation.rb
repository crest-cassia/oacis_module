require_relative 'extensible_orthogonal_table'
require_relative 'orthogonal_table'
require 'pry'

class ParameterSetGeneration
	# range_hashes = [
  #                   {"beta"=>[0.2, 0.6], "H"=>[-1.0, 1.0]},
  #                   ...
  #                ]

	#ps_block = {
  #             keys: ["beta", "H"],
  #             ps: [
  #                   {v: [0.2, -1.0], result: [-0.483285, -0.484342, -0.483428]},
  #                   ...
  #                 ],
  #             priority: 5.0,
  #             direction: "inside"
  #          }

  def initialize(module_data, step_size)
    @module_input_data = module_data.data["_input_data"]
    @step_size = step_size
    @xot = ExtensibleOrthogonalTable.new(module_data.data["_input_data"])
  end

  # 
  def get_initial_ps_block
    range_hash = @module_input_data["search_parameter_ranges"]
    parameter_values = get_parameter_values_from_range_hash(range_hash)
    # parameter_values = get_initial_parameter_values_extOT(range_hash)

  	ps_block = {}
    ps_block[:keys] = @module_input_data["search_parameter_ranges"].map {|name, ranges| name}
    ps_block[:ps] = []
    parameter_values.each_with_index do |ps_v, index|
      ps_block[:ps] << {v: ps_v, result: nil}
    end
    ps_block[:priority] = 1.0
    ps_block[:direction] = "outside"
    ps_block
  end

  #
  def get_initial_ps_block_by_extOT
    range_hash = @module_input_data["search_parameter_ranges"]
    parameter_values = []
    oa_param = @module_input_data["search_parameter_ranges"].map{|name, range|
      {name: name, paramDefs: [0, 1]}
    }
    ps_block = {}
    ps_block[:keys] = @module_input_data["search_parameter_ranges"].map {|name, ranges| name}
    ps_block[:ps] = []
    ps_block[:priority] = 1.0
    ps_block[:direction] = "outside"

    rows = []

    table = OrthogonalTable.generation_orthogonal_table(oa_param)
    table.transpose.each do |row|
      parameter_hash = {}
      regist_row_hash = {}
      oa_param.each_with_index do |param, idx|
        range = range_hash[param[:name]]
        parameter_value = range[ row[idx].to_i ]
        parameter_hash[param[:name]] = parameter_value
        regist_row_hash[param[:name]] = {"bit" => row[idx], "value" => parameter_value}
      end
      # parameter_values << @module_input_data["search_parameter_ranges"].map {|name, ranges| parameter_hash[name] }
      ps_v = @module_input_data["search_parameter_ranges"].map {|name, ranges| parameter_hash[name] }
      ps_block[:ps] << {v: ps_v, result: nil}
      rows << regist_row_hash
    end

    checked = @xot.initial_regist_rows(rows)
    ps_block
  end

  # 
  def new_ps_blocks(ps_block, mean_distances)
  	ps_blocks = []
		# => inside 
    mean_distances.each_with_index do |mean_distance, index|
      if mean_distance > @module_input_data["distance_threshold"]
        v_values = ps_block[:ps].map {|ps| ps[:v][index] }
        range = [v_values.min, v_values.max]
        one_third = range[0]*2 / 3 + range[1]   /3
        two_third = range[0]   / 3 + range[1]*2 /3
        one_third = one_third.round(6) if one_third.is_a?(Float)
        two_third = two_third.round(6) if two_third.is_a?(Float)
        ranges = [
          [range.first, one_third], [one_third, two_third], [two_third, range.last]
        ]
# test
        old_rows = []
        ranges.each do |r|
          old_rows << @xot.is_alredy_block_include_range({ps_block[:keys][index] => r})
        end
        if !old_rows.empty?
          @xot.get_rows(ps_block)
          binding.pry
        end
# =test
        range_hash = ps_block_to_range_hash(ps_block)
        ranges.each do |r|
          range_hash[ps_block[:keys][index]] = r
          ps = get_parameter_values_from_range_hash(range_hash)
          new_ps_block = {}
          new_ps_block[:keys] = ps_block[:keys]
          new_ps_block[:priority] = mean_distance
          new_ps_block[:direction] = "inside"
          new_ps_block[:ps] = ps.map {|p| {v: p}}
          ps_blocks << new_ps_block
        end
      end
    end
    # ==========

    # => outside
    if ps_block[:direction] != "inside"
      mean_distances.each_with_index do |mean_distance, index|
        v_values = ps_block[:ps].map {|ps| ps[:v][index] }
        range = [v_values.min, v_values.max]

        lower = range[0] - @step_size[ps_block[:keys][index]]
        upper = range[1] + @step_size[ps_block[:keys][index]]
        lower = lower.round(6) if lower.is_a?(Float)
        upper = upper.round(6) if upper.is_a?(Float)
        ranges = [
          [lower, range.first], [range.last, upper]
        ]

        range_hash = ps_block_to_range_hash(ps_block)
        ranges.each do |r|
          range_hash[ps_block[:keys][index]] = r
          ps = get_parameter_values_from_range_hash(range_hash)
          new_ps_block = {}
          new_ps_block[:keys] = ps_block[:keys]
          new_ps_block[:priority] = mean_distance
          new_ps_block[:direction] = "outside"
          new_ps_block[:ps] = ps.map {|p| {v: p}}
          ps_blocks << new_ps_block
        end
      end
    end
    # ==========
    ps_blocks
  end

  def new_ps_blocks_by_extOT(ps_block, mean_distances)
    ps_blocks = []
    # => inside 
    mean_distances.each_with_index do |mean_distance, index|
      if mean_distance > @module_input_data["distance_threshold"]
        v_values = ps_block[:ps].map {|ps| ps[:v][index] }
        range = [v_values.min, v_values.max]
        one_third = range[0]*2 / 3 + range[1]   /3
        two_third = range[0]   / 3 + range[1]*2 /3
        one_third = one_third.round(6) if one_third.is_a?(Float)
        two_third = two_third.round(6) if two_third.is_a?(Float)
        ranges = [
          [range.first, one_third], [one_third, two_third], [two_third, range.last]
        ]

        ranges.each do |range| 
          @xot.is_alredy_block_include_range({ps_block[:keys][index] => range})
        end

        # range_hash = ps_block_to_range_hash(ps_block) <- modify

        ranges.each do |r|
          range_hash[ps_block[:keys][index]] = r
          ps = get_parameter_values_from_range_hash(range_hash)
          # get_parameter_values_from_range_hash_extOT(range_hash) <- modified method
          new_ps_block = {}
          new_ps_block[:keys] = ps_block[:keys]
          new_ps_block[:priority] = mean_distance
          new_ps_block[:direction] = "inside"
          new_ps_block[:ps] = ps.map {|p| {v: p}}
          ps_blocks << new_ps_block
        end
      end
    end
    # ==========

    # => outside
    if ps_block[:direction] != "inside"
      mean_distances.each_with_index do |mean_distance, index|
        v_values = ps_block[:ps].map {|ps| ps[:v][index] }
        range = [v_values.min, v_values.max]

        lower = range[0] - @step_size[ps_block[:keys][index]]
        upper = range[1] + @step_size[ps_block[:keys][index]]
        lower = lower.round(6) if lower.is_a?(Float)
        upper = upper.round(6) if upper.is_a?(Float)
        ranges = [
          [lower, range.first], [range.last, upper]
        ]

        # range_hash = ps_block_to_range_hash(ps_block) <- modify

        ranges.each do |r|
          range_hash[ps_block[:keys][index]] = r
          ps = get_parameter_values_from_range_hash(range_hash)
          # get_parameter_values_from_range_hash_extOT(range_hash)
          new_ps_block = {}
          new_ps_block[:keys] = ps_block[:keys]
          new_ps_block[:priority] = mean_distance
          new_ps_block[:direction] = "outside"
          new_ps_block[:ps] = ps.map {|p| {v: p}}
          ps_blocks << new_ps_block
        end
      end
    end
    # ==========
    ps_blocks
  end

  # 
  def ps_block_with_id_set(ps_block)
    # parameter_set_block =
    #   { :id_set => [012345, 98765, 24680, .... ]
    #     :v_set => [ {"beta" => 0.2, "H" => 0.4},
    #                 {"beta" => 0.2, "H" => 0.6},
    #                 {"beta" => 0.4, "H" => 0.4},
    #                  ...
    #               ]
    #   }
    #
    with_id_set = {:id_set => [], :v_set => [] }
    ps_block[:ps].each do |ps|
      parameter_set = {}
      ps[:v].each_with_index do |value, index|
        parameter_set[ps_block[:keys][index]] = value
      end
      query = {}
      parameter_set.each{|k,v| query["v.#{k}"] = v }
      with_id_set[:id_set] << ParameterSet.where(query).first._id
      with_id_set[:v_set] << parameter_set
    end
    with_id_set
  end


  private
  def ps_block_to_range_hash(ps_block)

    range_hash = {}
    ps_block[:keys].each_with_index do |key, index|
      v_values = ps_block[:ps].map {|ps| ps[:v][index] }
      range_hash[key] = [v_values.min, v_values.max]
    end
    range_hash
  end

  # 
  def get_parameter_values_from_range_hash(range_hash)

    parameter_values = []
    oa_param = @module_input_data["search_parameter_ranges"].map{|name, range|
    	{name: name, paramDefs: [0, 1]}
    }

    table = OrthogonalTable.generation_orthogonal_table(oa_param)

    table.transpose.each do |row|
      parameter_hash = {}
      oa_param.each_with_index do |param, idx|
      	range = range_hash[param[:name]]
        parameter_value = range[ row[idx].to_i ]
        parameter_hash[param[:name]] = parameter_value
      end
      parameter_values << @module_input_data["search_parameter_ranges"].map {|name, ranges| parameter_hash[name] }
    end

    parameter_values
  end

  # def get_parameter_values_from_range_hash_extOT(range_hash, ps_block)
    
  # end
end