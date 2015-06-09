require 'rsruby'
require 'csv'
require 'json'
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

#
def simulate_one_parameter_set(population, evacuate_area, sample_size)
  ticks = []
  out_dir = "./#{population}/#{evacuate_area.join("_")}"

  sample_size.times.each{|seed|
    create_crowdwalk_kamakura_file(population, evacuate_area, out_dir, seed)
    ticks << do_crowdwalk("#{out_dir}", "properties_#{seed}.json")
  }
  open("#{out_dir}/_output.json", "w"){|io| io.write(ticks.to_s)}
  return ticks.inject(:+)/ticks.size
end

#
def execute_crowdwalk_parallel(parameter_sets, sample_size, process_num=4)
  require 'parallel'  

  Parallel.each(parameter_sets, :in_processes=>process_num){|ps|
    set = ps.map{|v| v.to_i}
    evacuate_area = set[0..6]
    population = set[7]

    # p "#{evacuate_area} : #{population}"
    average = simulate_one_parameter_set(population, evacuate_area, sample_size)
  }
end

#= = = = CrowdWalk = = = =



# 
def main_loop(process_num=4, input_file="./_input.json")
  
  # initialize
  init_params = JSON.load(open(input_file,"r"))
  doe_search = Doe::DoeSearch.new(init_params["definitions"])

  parameter_sets = doe_search.create_parameter_set(init_params["parameters"])
  headers = parameter_sets.map{|k,v| k}
  parameter_sets = parameter_sets.map{|k,v| v}.transpose

  parallel_job_size = 4
  sample_size = 3
  

  # loop{
  # 
  # }
  while !parameter_sets.empty?
    jobs = parameter_sets.shift(parallel_job_size)
    execute_crowdwalk_parallel(jobs, sample_size, parallel_job_size)  
  end

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

  doe_search = Doe::DoeSearch.new(init_params["definitions"])

  parameter_sets = doe_search.create_parameter_set(init_params["parameters"])
  headers = parameter_sets.map{|k,v| k}
  parameter_sets = parameter_sets.map{|k,v| v}.transpose

  parameter_sets.each{|ps|
    set = ps.map{|v| v.to_i}
    evacuate_area = set[0..6]
    population = set[7]
    p "#{evacuate_area} : #{population}"
  }

  debug_result_test(init_params, headers, parameter_sets)

  binding.pry
end

#
def debug_test_sitevisit
  require 'pry'
  headers, *parameter_sets = CSV.read('./oaTable_18x9.csv') #162 rows
  execute_crowdwalk_parallel(parameter_sets, 3, 4)
end

#
def debug_result_test(init_params, headers, parameter_sets)
  require 'pry'

  target_names=init_params["definitions"]["targets"]
  targets = target_names.map{|name| 
    [name, init_params["parameters"][name].map{|v| [v,[]] }.to_h]
  }

  targets = targets.to_h

  parameter_sets.each{|ps|
    dir = "#{ps[7].to_i}/#{ps[0..6].join("_")}"
    f_path = dir + "/_output.json"
    ticks = JSON.load(open(f_path))

    targets[headers[7]][ps[7].to_i] += ticks
  }

  result = targets[headers[7]].map{|k,v| [k, v.inject(:+)/v.size]}.to_h
  # 5000~7500
  a1 = (result[7500] - result[5000]) / (7500 - 5000)
  # 7500~10000
  a2 = (result[10000] - result[7500]) / (10000 - 7500)
  binding.pry
end

# 
if __FILE__ == $0

  # debug_test
  debug_test_rsruby
  
  exit(0)

  # for_sitevisit
  debug_test_sitevisit
end