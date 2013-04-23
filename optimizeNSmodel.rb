require 'environment'
require 'pp'

def create_simulator
  name = 'NSmodelWithTrafficSignals'
  execution_command = Rails.root.join('vendor','sample_simulators','NS_model','traffic_NSmodel.rb')
  description = <<-EOS
    Nagel-Schreckenberg model with two traffic signals.
    There are two lanes on which cars go through in the opposite direction.
    Cars appear on both sides following Poisson process with parameter 'lambda'.
    Two signals locates at x=40 and 70.
    The interval of the signals are specified by T_signal1 and T_signal2.
    ....
  EOS

  h = { "L" => {"type"=>"Integer", "description" => "Length of lanes"},
        "V_max" => {"type"=>"Integer", "description" => "Maximum velocity of cars"},
        "lambda" => {"type"=>"Float", "description" => "Probability that cars appear"},
        "T_signal1" => {"type"=>"Integer", "description" => "Interval of the first signal"},
        "T_signal2" => {"type"=>"Integer", "description" => "Interval of the second signal"},
        "signal_phase_diff" => {"type"=>"Integer", 
          "description" => "Phase difference of two signals. must be less than min(T_signal1*2, T_signal2*2)"},
        "T_movie" => {"type"=>"Integer", "description" => "Duration during which configuration of cars are dumped."}
      }
  sim = Simulator.create!(name: name,
                          execution_command: execution_command,
                          parameter_definitions: h,
                          description: description)
  return sim
end

# prepare simulator
sim = Simulator.where(name: "NSmodelWithTrafficSignals").first or create_simulator
pp sim

# set range of parameters
default_values = { "L" => 75,
                   "V_max" => 5,
                   "lambda" => 5,
                   "T_signal1" => 10,
                   "T_signal2" => 10,
                   "signal_phase_diff" => 7,
                   "T_movie" => 200
                 }

# int1_ary = [2,4,8,10,15,20,30]
# int1_ary = [10]
t1 = 10
int2_ary = [10,12,14,16,18,20]
phase_ary = (0..19).to_a

NUM_RUNS = 4
int2_ary.each do |t2|
  phase_ary.each do |phs|
    next if phs >= [t1*2,t2*2].min
    param_values = default_values.update(
      {"T_signal1" => t1, "T_signal2" => t2, "signal_phase_diff" => phs} )
    pp param_values
    prm = sim.parameters.where(:sim_parameters => param_values).first
    prm = sim.parameters.create!(:sim_parameters => param_values) unless prm
    (NUM_RUNS - prm.runs.count).times do |i|
      run = prm.runs.create!
      run.submit
    end
  end
end
