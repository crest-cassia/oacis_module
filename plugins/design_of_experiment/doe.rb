require 'json'
require_relative '../../lib/OACIS_module.rb'
require_relative '../../lib/OACIS_module_data.rb'
require_relative 'mean_test'
require_relative 'f_test'
require_relative 'orthogonal_table'
require_relative 'parameter_set_generation'
require_relative './controllers/doe_result_controller'
require_relative './controllers/orthogonal_controller'

class Doe < OacisModule

  def self.definition
    h = {}
    h["ps_block_count_max"] = 1000
    h["distance_threshold"] = 0.1
    h["target_field"] = "order_parameter"
    h["concurrent_job_max"] = 30
    h["search_parameter_ranges"] = {
      # ex.) 
      # "beta" => [0.5, 0.6],
      # "H" => [-0.1, 0.0]
    }
    h["step_size"] = {}
    h["search_parameter_ranges"].each do |key, range|
      h["step_size"][key] = range.max-range.min
      h["step_size"][key] = h["step_size"][key].round(6) if range.first.is_a?(Float)
    end
    h
  end

  def initialize(input_data)
    super(input_data)

    @doe_result_controller = DOEResultController.new    
    @total_ps_block_count = 0
    step_size = module_data.data["_input_data"]["step_size"]
    @ps_generation = ParameterSetGeneration.new(module_data, step_size)

    @ps_block_list = []
    @ps_block_list << @ps_generation.get_initial_ps_block
  end

  private
  #override
  def generate_runs

    @ps_block_list.sort_by! {|ps_block| -ps_block[:priority]}
    ps_count = 0
    num_jobs = module_data.data["_input_data"]["concurrent_job_max"]
    @running_ps_block_list = @ps_block_list.shift(num_jobs)
    @running_ps_block_list.each do |ps_block|
      ps_block[:ps].each do |ps|
        module_data.set_input(@num_iterations, ps_count, ps[:v])
        ps_count += 1
      end
    end

    super
  end

  #override
  def evaluate_runs

    super

    ps_count = 0
    @running_ps_block_list.each do |ps_block|
      ps_block[:ps].each do |ps|
        ps[:result] = module_data.get_output(@num_iterations, ps_count)
        ps_count += 1
      end
    end

    @running_ps_block_list.each do |ps_block|
      mean_distances = MeanTest.mean_distances(ps_block)

      ps_block_with_id_set = @ps_generation.ps_block_with_id_set(ps_block)
      result_block = ps_block[:keys].each_with_index.map {|key, index| 
        {key => mean_distances[index]}
      }

      sim = module_data.data["_input_data"]["_target"]["Simulator"]
      @doe_result_controller.create(sim, ps_block_with_id_set, result_block)
      
      @ps_generation.new_ps_blocks(ps_block, mean_distances).each do |new_ps_block|
        @ps_block_list << new_ps_block if !is_duplicate(new_ps_block)
      end
    end

    @total_ps_block_count += @running_ps_block_list.size
  end

  #override
  def finished?

    puts "# of ps_block_list.size = #{@ps_block_list.size}"
    puts "total_ps_block_count = #{@total_ps_block_count}"
    @ps_block_list.empty? or @total_ps_block_count > module_data.data["_input_data"]["ps_block_count_max"]
  end

  #override
  def get_target_fields(result)
    result.try(:fetch, module_data.data["_input_data"]["target_field"])
  end

  # 
  def is_duplicate(check_block)
    dup = false
    return dup if @ps_block_list.empty?
    @ps_block_list.each do |ps_block|
      dup = true
      ps_block[:ps].each do |values|
        if check_block[:ps].include?(values)
          dup &= true
        else
          dup &= false
        end
      end
      return dup if dup
    end
    dup = @doe_result_controller.duplicate(sim, check_block)

    return dup
  end
end
