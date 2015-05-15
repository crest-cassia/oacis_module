require 'json'
require_relative '../../lib/OACIS_module.rb'
require_relative '../../lib/OACIS_module_data.rb'
require 'csv'

class SampleModule < OacisModule

  # this definition is used by OACIS_module_installer
  def self.definition
    h = {}
    h["z1"]=0
    h["z2"]=0
    h["z3"]=0
    h["z4"]=0
    h["z5"]=0
    h["z6"]=0
    h["o5"]=0
    h["population"]=7500
    h
  end

  # data contains definitions whose values are given as ParameterSet.v in OACIS_module_simulator
  def initialize(_input_data)
    super(_input_data)
    table = CSV.read("/home/oacis/work/oacis_module/plugins/EvacuationAnalysis_18x9/src/oaTable_18x9.csv")
    @oaTable = []
    table[1..-1].each do |t|
      t2 = t.map {|val| val.to_i}
      7.times do |i|
        t2[i] = t2[i] - 1
      end
      @oaTable << t2
    end
  end

  private
  #override
  def get_target_fields(result)
    result.try(:fetch, "EvacuationTime")
  end

  #override
  def generate_runs #define generate_runs afeter update_particle_positions
    set_parameter
    super
  end

  #override
  def evaluate_runs
    super
    evaluate_parameter
 end

  #override
  def finished?
    return true
  end

  def set_parameter
    #set parameter value to module_data
    @oaTable.each_with_index do |val, i|
      module_data.set_input(@num_iterations, i, val)
    end
  end

  def evaluate_parameter
    @oaTable.each_with_index do |ps, i|
      puts "input=#{ps} output=#{module_data.get_output(@num_iterations, i)}"
    end
    populations = [70, 500, 1000, 1500, 2000, 2500, 5000, 7500, 10000]
    io = CSV.open("result.csv", "w")
    io << managed_parameters_table[0..6].map {|mpt| mpt["key"]} + populations
    @oaTable.each_with_index do |ps, i|
      pop_i = populations.index(ps[7])
      a = Array.new(populations.size).fill(0)
      a[pop_i] = module_data.get_output(@num_iterations, i)[0]
      io << ps[0..6] + a
    end
    io.flush
    io.close
  end
end

