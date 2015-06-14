require 'rsruby'
require 'csv'
require 'json'
require 'optparse'
require 'fileutils'
require_relative './rsruby_doe'


#= = = = CrowdWalk = = = =

KAMAKURA_DIR_PATH="#{ENV["HOME"]}/Desktop/kamakura_sitevisit_demo"

CROWDWALK_PROGRAM_PATH="#{ENV["CROWDWALK"]}"
MAP_PATH="#{KAMAKURA_DIR_PATH}/map_narrow.xml"
SCENARIO_PATH="#{KAMAKURA_DIR_PATH}/scenario.csv"

KAMAKURA_BASIC_POPULATION=
{ #"z1"=>1005,"z2"=>957,"z3"=>1479,"z4"=>643,"z5"=>1385,"z6"=>1148, "o5"=>711 
  "ZAIMOKU1"=>1005,"ZAIMOKU2"=>957,
  "ZAIMOKU3"=>1479,"ZAIMOKU4"=>643,
  "ZAIMOKU5"=>1385,"ZAIMOKU6"=>1148,
  "OHMACHI5"=>711
}

KAMAKURA_POPULATION_RATIO=
{
  "ZAIMOKU1"=>0.13714519650655022,
  "ZAIMOKU2"=>0.13059497816593887,
  "ZAIMOKU3"=>0.20182860262008734,
  "ZAIMOKU4"=>0.08774563318777293,
  "ZAIMOKU5"=>0.18900109170305676,
  "ZAIMOKU6"=>0.1566593886462882,
  "OHMACHI5"=>0.09702510917030567 
}

EVACUATION_PLACES=
[ "NAGHOSHI_CLEAN_CENTER_EXIT", 
  "OLD_MUNICIPAL_HOUSING_EXIT",
  "KAMAKURA_Jr_HIGH_EXIT"
]

#
def create_crowdwalk_kamakura_file(population, evacuate_area, out_dir="./kamakura_test", seed=0)

  FileUtils.mkdir_p(out_dir) if !Dir.exist?(out_dir)

  #gen.csv
  create_gen_file(population, evacuate_area, out_dir)

  #properties.json
  map_path=MAP_PATH
  scenario_path=SCENARIO_PATH
  gen_path = "#{out_dir}/gen.csv"
  create_properties_json(map_path, scenario_path, gen_path, out_dir, seed)
end

#
def create_gen_file(population, evacuate_area, out_dir)
  evacuators = {}
  KAMAKURA_POPULATION_RATIO.each{|k,v| evacuators[k] = v*population }
  sum = evacuators.map{|k,v| v.floor }.inject(:+)

  if sum < population
    dif = population - sum
    if dif > 7
      raise "dif size is bigger than 7 !!"
    end
    added = evacuators.sort_by{|k,v| v}.shift(dif)
    added.each{|k,v|
      evacuators[k] += 1
    }
  end

  rows = []
  evacuators.each.with_index{|evac,i|
    EVACUATION_PLACES.each_with_index{|place,j|
      if evacuate_area[i] == j
        rows << [
          "TIMEEVERY", "#{evac[0]}", "18:00:00", "18:00:00",
          1, 1, "#{evac[1].floor}", "PLAIN", "#{place}"
        ]
      # else
      #   rows << [
      #     "TIMEEVERY", "#{evac[0]}", "18:00:00", "18:00:00",
      #     1, 1, 0, "PLAIN", "#{place}"
      #   ]
      end
    }
  }

  CSV.open("#{out_dir}/gen.csv", "w"){|io|
    rows.each{|row| io << row}
  }
end
#
def create_properties_json(map_path, scenario_path, gen_path, out_dir, seed=0)
  h = {
    "__0" => "NetmasCuiSimulator",
    "debug" => false,
    "io_handler_type" => "none",
    "map_file" => "#{map_path}",
    "generation_file" => "#{gen_path}",
    "scenario_file" => "#{scenario_path}",
    "timer_enable" => false,
    "timer_file" => "tmp/timer.log",
    "interval" => 0,
    "randseed" => seed,
    "random_navigation" => false,
    "speed_model" => "density",
    "time_series_log" => false,
    "time_series_log_path" => "tmp",
    "time_series_log_interval" => 1,
    "loop_count" => 1,
    "exit_count" => 0,
    "all_agent_speed_zero_break" => false
  }
  json_str = JSON.pretty_generate(h)
  open("#{out_dir}/properties_#{seed}.json", "w"){|io| io.write(json_str)}
end

#
def do_crowdwalk(dir, properties_file_name="properties.json", seed=0)
  cmd = "sh #{CROWDWALK_PROGRAM_PATH}/quickstart.sh --cui"
  cmd += " #{dir}/#{properties_file_name} -t #{dir}/tick_#{seed}.txt"

  system(cmd)

  tick = nil
  open("#{dir}/tick_#{seed}.txt", "r"){|io| tick = io.read.to_f }
  
  return tick
end

# #:TODO
def simulate_one_parameter_set(population, evacuate_area, sample_size, out_dir=nil)
  ticks = []
  out_dir = "./#{population}/#{evacuate_area.join("_")}" if out_dir.nil?

  if check_already(out_dir, sample_size)
    ticks = JSON.load(open("#{out_dir}/_output.json"))
  else
    sample_size.times.each{|seed|
    create_crowdwalk_kamakura_file(population, evacuate_area, out_dir, seed)
    ticks << do_crowdwalk("#{out_dir}", "properties_#{seed}.json")
  }
    open("#{out_dir}/_output.json", "w"){|io| io.write(ticks.to_s)}
  end
  
  return ticks.inject(:+)/ticks.size
end
#
def check_already(out_dir, sample_size)
  result_file = "#{out_dir}/_output.json"
  if File.exist?(result_file)
    res = JSON.load(open(result_file))
    if res.nil? || res.empty? || res.size < sample_size
      return false
    else
      return true
    end
  else
    return false
  end
end

# pss: [evacuate_area, population]
def execute_crowdwalk_parallel(c_headers, t_headers, parameter_sets, sample_size, process_num=4)
  require 'parallel'

  # parameter_sets.each{|ps|
  Parallel.each(parameter_sets, :in_processes=>process_num){|ps|
    params = extract_crowdwalk_parameter(c_headers, t_headers, ps)
    evacuate_area = params[0..6]
    population = params[7]

    const_id_range = 0..(c_headers.size-1)
    target_id_range = c_headers.size..(c_headers.size+t_headers.size-1)
    parent_dir = "#{ps[target_id_range].map{|v| v.to_i }.join("_")}"
    dir = "#{parent_dir}/#{ps[const_id_range].join("_")}"
    
    average = simulate_one_parameter_set(population, evacuate_area, sample_size, dir)
  }
end
#
def extract_crowdwalk_parameter(c_headers, t_headers, parameters)
  default_params = ["z1", "z2", "z3", "z4", "z5", "z6", "o5", "population"]
  headers = c_headers+t_headers
  ids = []
  default_params.each{|name|
    ids << headers.index(name)
  }
  extract = parameters.select.with_index{|v,i| ids.include?(i) }
  return extract
end

#= = = = CrowdWalk = = = =

#= = = = DoE = = = = 

# # TODO: modify parameter_sets
def doe_aov(target_name, target_params, c_headers, t_headers, parameter_sets)
  target = target_params.map{|v| [v,[]] }.to_h
  headers = c_headers+t_headers
  target_id = headers.index(target_name)

  const_id_range = 0..(c_headers.size-1)
  target_id_range = c_headers.size..(headers.size-1)

  parameter_sets.each{|ps|
    parent_dir = "#{ps[target_id_range].map{|v| v.to_i }.join("_")}"
    dir = "#{parent_dir}/#{ps[const_id_range].join("_")}"
    f_path = dir + "/_output.json"
    ticks = JSON.load(open(f_path))

    target[ps[target_id].to_i] += ticks
  }

  x1, x2, x3 = target.map{|k, v| k}
  y1, y2, y3 = target.map{|k, v| v}

  return res = Doe::aov(x1, x2, x3, y1, y2, y3)
end

#
def cor_plot(param_defs, t_headers, parameter_sets)
  binding.pry
  columns = parameter_sets.transpose
  data_set = []
  param_defs.each{|k, v|

  }
  Doe::cor_plot(headers, parameter_sets.transpose)
  binding.pry
end

#
def create_divide_parameters(target_name, parameters, limit)
  check = parameters[target_name].sort
  l_flag = (limit["interval"] < check[1] - check[0])
  u_flag = (limit["interval"] < check[2] - check[1])

  new_parameters1, new_parameters2 = {}, {}
  parameters.each{|k, v|
    if k == target_name
      params = parameters[target_name].sort
      # 1
      if l_flag
        divide_point1 = (params[0] + params[1]) / 2
        new_parameters1[k] = [params[0], divide_point1, params[1]]
      end
      #2
      if u_flag
        divide_point2 = (params[1] + params[2]) / 2
        new_parameters2[k] = [params[1], divide_point2, params[2]]
      end
    else
      new_parameters1[k] = v if l_flag
      new_parameters2[k] = v if u_flag
    end
  }
  # binding.pry
  return new_parameters1, new_parameters2
end
#
def create_expand_parameters(target_name, parameters, limit)
  # check
  check = parameters[target_name].sort
  l_flag = check[0] > limit["lower"]
  u_flag = check[2] < limit["upper"]

  new_parameters1, new_parameters2 = {}, {}
  parameters.each{|k,v|
    if k == target_name
      params = parameters[target_name].sort
      # 1
      if l_flag
        expand_point1 = (params[0] - limit["expand"])
        expand_point1 = limit["lower"] if expand_point1 < limit["lower"]
        new_parameters1[k] = [expand_point1, params[0], params[1]]
      end
      #2
      if u_flag
        expand_point2 = (params[2] + limit["expand"])
        expand_point2 = limit["upper"] if expand_point2 > limit["upper"]
        new_parameters2[k] = [params[1], params[2], expand_point2]
      end
    else
      new_parameters1[k] = v if l_flag
      new_parameters2[k] = v if u_flag
    end 
  }
  return new_parameters1, new_parameters2
end

# 
def main_loop(process_num=4, input_file="./_input.json")
  
  # initialize
  sample_size = 3

  init_params = JSON.load(open(input_file,"r"))
  definitions = init_params["definitions"]
  constracts = init_params["constractions"]
  c_headers = init_params["definitions"]["consts"]
  t_headers = init_params["definitions"]["targets"]
  execution_ps_queue = []
  ini = init_params["parameters"]
  ini["direction"] = "outside"
  execution_ps_queue << ini

  doe_search = Doe::DoeSearch.new(definitions)

  already_executed = []

  while execution_ps_queue.count > 0
    parameters = execution_ps_queue.shift
    
    direction = parameters["direction"]
    parameters.delete("direction")

    already_executed << parameters
    parameter_sets = doe_search.create_parameter_set(parameters)
    headers = parameter_sets.map{|k,v| k}
    parameter_sets = parameter_sets.map{|k,v| v}.transpose


    # # TODO: modify
    # require 'pry'
    # binding.pry
    execute_crowdwalk_parallel(c_headers, t_headers, parameter_sets, sample_size, process_num)
    # binding.pry
    definitions["targets"].each{|target_name|
      # TODO: modify
      if doe_aov(target_name, parameters[target_name], c_headers, t_headers, parameter_sets)
        # search dividing point
        new_param1, new_param2 = create_divide_parameters(target_name, parameters, constracts[target_name])
        if !new_param1.empty? && !already_executed.include?(new_param1)
          new_param1["direction"] = "inside"
          execution_ps_queue.unshift(new_param1)
        end
        if !new_param2.empty? && !already_executed.include?(new_param2)
          new_param2["direction"] = "inside"
          execution_ps_queue.unshift(new_param2)
        end
      elsif direction == "outside"
        # expand range
        new_param1, new_param2 = create_expand_parameters(target_name, parameters,constracts[target_name])
        if !new_param1.empty? && !already_executed.include?(new_param1)
          new_param1["direction"] = "outside"
          execution_ps_queue << new_param1
        end
        if !new_param2.empty? && !already_executed.include?(new_param2)
          new_param2["direction"] = "outside"
          execution_ps_queue << new_param2
        end
      end
    }
  end

  jstr = JSON.pretty_generate(already_executed)
  open("./parameter_sets.json","w"){|io| io.write(jstr)}
end



#
def debug_test
  require 'pry'
  require 'benchmark'

  average = 0
  result_time = Benchmark.realtime do
    sample_size = 1

    evacuate_area = [1,1,2,2,0,0,1]# z1,z2,z3,z4,z5,z6,o5
    populations = [70,500,1000,1500,2000,2500,5000,7500,10000]

    average = simulate_one_parameter_set(populations[2], evacuate_area, sample_size)  
  end

  p "simulation time: #{result_time}"

  binding.pry
end

#
def debug_test_rsruby(input_file="./_input.json")
  require 'pry'

  init_params = JSON.load(open(input_file,"r"))
  definitions = init_params["definitions"]
  constracts = init_params["constractions"]
  c_headers = init_params["definitions"]["consts"]
  t_headers = init_params["definitions"]["targets"]
  execution_ps_queue = []
  ini = init_params["parameters"]
  ini["direction"] = "outside"
  execution_ps_queue << ini

  doe_search = Doe::DoeSearch.new(definitions)

  already_executed = []

  while execution_ps_queue.count > 0
    parameters = execution_ps_queue.shift
    
    direction = parameters["direction"]
    parameters.delete("direction")

    already_executed << parameters
    parameter_sets = doe_search.create_parameter_set(parameters)
    headers = parameter_sets.map{|k,v| k}    
    parameter_sets = parameter_sets.map{|k,v| v}.transpose

    # TODO: modify parameter_sets
    const_id_range = 0..(c_headers.size-1)
    target_id_range = c_headers.size..(headers.size-1)

    parameter_sets.each{|ps|
      set = ps.map{|v| v.to_i}
      evacuate_area = set[const_id_range]
      population = set[target_id_range]
      p "#{evacuate_area} : #{population}"
    }

    # cor.plot
    cor_plot(parameters, t_headers, parameter_sets)

    t_headers.each{|target_name|
      if doe_aov(target_name, parameters[target_name], c_headers, t_headers, parameter_sets)
        # search dividing point
        new_param1, new_param2 = create_divide_parameters(target_name, parameters, constracts[target_name])
        if !new_param1.empty? && !already_executed.include?(new_param1)
          new_param1["direction"] = "inside"
          execution_ps_queue.unshift(new_param1)
        end
        if !new_param2.empty? && !already_executed.include?(new_param2)
          new_param2["direction"] = "inside"
          execution_ps_queue.unshift(new_param2)
        end
        # binding.pry # search dividing point
      elsif direction == "outside"
        # expand range
        # test_parameters = test_params
        # execution_ps_queue << test_parameters
        new_param1, new_param2 = create_expand_parameters(target_name, parameters,constracts[target_name])
        if !new_param1.empty? && !already_executed.include?(new_param1)
          new_param1["direction"] = "outside"
          execution_ps_queue << new_param1
        end
        if !new_param2.empty? && !already_executed.include?(new_param2)
          new_param2["direction"] = "outside"
          execution_ps_queue << new_param2
        end
        # binding.pry # expand range
      end
    }

    binding.pry
  end
  jstr = JSON.pretty_generate(already_executed)
  open("./parameter_sets.json","w"){|io| io.write(jstr)}
  binding.pry
end


#
def test_params
  return {"z1"=>[0, 1, 2],
  "z2"=>[0, 1, 2],
  "z3"=>[0, 1, 2],
  "z4"=>[0, 1, 2],
  "z5"=>[0, 1, 2],
  "z6"=>[0, 1, 2],
  "o5"=>[0, 1, 2],
  "population"=>[1000, 3000, 5000]}
end

#
def debug_test_sitevisit
  require 'pry'

  headers, *parameter_sets = CSV.read('./oaTable_18x9_2.csv') #162 rows
  execute_crowdwalk_parallel(parameter_sets, 3, 4)

  exit(0)

  # = = = all pattern = = = 
  base = [0,1,2]
  list = base.product(base).map{|a| a.flatten}
  5.times{list = list.product(base).map{|a| a.flatten}}

  populations = [70,500,1000,2000,3000,4000,5000,6000,7000,7500,8000,9000,10000]
  all_patterns = list.product(populations).map{|a| a.flatten }
  execute_crowdwalk_parallel(all_patterns, 3, 4)
end


def test_sum_result
  require 'pry'

  # files = Dir.glob("/media/547E-838B/sitevisit/*/*/_output.json")
  out_result = {}

  files.each{|f|
    res = JSON.load(open(f))
    average = res.inject(:+)/res.size

    paths = f.split("/")
    out_result[paths[5]] ||= {}
    out_result[paths[5]][paths[4]] = average
    
  }

  
  CSV.open("out_result.csv", "w"){|row|
    out_result.each{|oa_str, hash|
      oa = oa_str.split("_")
      arr = hash.sort_by{|k,v| k.to_i}
      aves = arr.map{|a| a[1]}
      row << oa + aves
    }
  }
  binding.pry
end

# target_param = {"name" => [x1, x2, x3]}
# 
def option_parse(options)
  @input = options["i"]
  @num_process = options["p"].to_i
end

# 
if __FILE__ == $0
  options = ARGV.getopts("i:p:")
  option_parse(options)

  main_loop(@num_process, @input)

  # debug_test
  debug_test_rsruby
  exit(0)

  # for_sitevisit
  debug_test_sitevisit

  # etc., ...
  # test_sum_result
end