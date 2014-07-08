require 'json'
require_relative '../../lib/OACIS_module.rb'
require_relative '../../lib/OACIS_module_data.rb'
require_relative 'mean_test'
require_relative 'f_test'
require_relative 'orthogonal_table'
require_relative 'parameter_set_generation'
require_relative './controllers/doe_result_controller'
require_relative './controllers/orthogonal_controller'

class Xdoe < OacisModule

  def self.definition
    h = {}
    h["ps_block_count_max"] = 2000
    h["distance_threshold"] = 8 #0.1
    h["target_field"] = "result"
    h["concurrent_job_max"] = 50
    h["search_parameter_ranges"] = {
      # ex.) 
      # "beta" => [0.5, 0.6],
      # "H" => [-0.1, 0.0]
      "x" => [0.2, 0.3],
      "y" => [0.4, 0.5],
      "z" => [0.6, 0.7]
    }
    h["step_size"] = {}
    h["search_parameter_ranges"].each do |key, range|
      h["step_size"][key] = range.max-range.min
      h["step_size"][key] = h["step_size"][key].round(6) if range.first.is_a?(Float)
    end
    h["epsilon"] = 0.2
    h
  end

  def initialize(input_data)
    super(input_data)
    @seed = 0
    @prng = Random.new(@seed)

    @doe_result_controller = DOEResultController.new
    @total_ps_block_count = 0
    step_size = module_data.data["_input_data"]["step_size"]
    @ps_generation = ParameterSetGeneration.new(module_data, step_size)

    @ps_block_list = []
    new_ps_block = @ps_generation.get_initial_ps_block_by_extOT
    @ps_block_list << new_ps_block

    @dup_count = 0
    @created_ps_block = 0
  end

  private
  #override
  def generate_runs

    @ps_block_list.sort_by! {|ps_block| -ps_block[:priority]}
    ps_count = 0
    num_jobs = module_data.data["_input_data"]["concurrent_job_max"]
    @running_ps_block_list = @ps_block_list.shift(num_jobs)
    @created_ps_block += @running_ps_block_list.size
    @running_ps_block_list.each do |ps_block|
      ps_block[:ps].each do |ps|
        module_data.set_input(@num_iterations, ps_count, ps[:v])
        ps_count += 1
      end
    end

    p "created ps_block: #{@created_ps_block}"
    p "ps_block_list: #{@ps_block_list.size}"

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
      # mean_distances = MeanTest.mean_distances(ps_block)
      mean_distances = FTest.eff_facts(ps_block)

      # ps_block_with_id_set = @ps_generation.ps_block_with_id_set(ps_block)
      id_list = @ps_generation.id_list_of_ps_block(ps_block) # sorted list
      result_block = ps_block[:keys].each_with_index.map {|key, index| 
        {key => mean_distances[index]}
      }

      sim = module_data.data["_input_data"]["_target"]["Simulator"]
      # @doe_result_controller.create(sim, ps_block_with_id_set, result_block)
      @doe_result_controller.create(sim, ps_block, id_list, result_block)
      
      new_ps_blocks = @ps_generation.new_ps_blocks_by_extOT(ps_block, mean_distances, @prng)
      new_ps_block_size = new_ps_blocks.size
      local_dup_count = 0
      new_ps_blocks.each do |new_ps_block|
        if !is_duplicate(new_ps_block)
          @ps_block_list << new_ps_block
          p "current ps_block size: #{@ps_block_list.size}"
        else
          local_dup_count += 1
          p "duplicated: #{local_dup_count} / #{new_ps_block_size}"
          @dup_count += 1
        end
      end
    end
    p "running ps_block size: #{@running_ps_block_list.size}"
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
    binding.pry if check_block.nil? # 
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

    # if !dup
    #   sim = module_data.data["_input_data"]["_target"]["Simulator"]
    #   dup = @doe_result_controller.duplicate(sim, check_block)
    # end

    return dup
  end

  # 
  def extract_unique_block(check_blocks)
    #ps_block = {
    #             keys: ["beta", "H"],
    #             ps: [
    #                   {v: [0.2, -1.0], result: [-0.483285, -0.484342, -0.483428]},
    #                   ...
    #                 ],
    #             priority: 5.0,
    #             direction: "inside"
    #          }

    check_blocks -= @ps_block_list


  end
end
