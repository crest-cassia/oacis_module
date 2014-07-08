require 'pry'

module FTest


  #[
  #  {:name=>0,
  #   :results=>{
  #                0.2=>[
  #                       -0.483285
  #                       ...,
  #                       0.484342
  #                     ],
  #                0.6=>[
  #                       -0.994595,
  #                       ...,
  #                       0.994443
  #                     ]
  #              }
  #   :effect=>1.4620500000005297e-07,
  #   :free=>1,
  #   :f_value=>1.9038296239370828e-06
  #  },
  #  {name=>1,
  #  ...
  #]
  def self.eff_facts(ps_block)

    #ps_block = {
    #             keys: ["beta", "H"],
    #             ps: [
    #                   {v: [0.2, -1.0], result: [-0.483285, -0.484342, -0.483428]},
    #                   ...
    #                 ],
    #          }

    @mean = 0
    @ss = 0
    @count = 0

    ps_block[:ps].each do |ps|
      cycle_array = ps[:result]
      @mean += cycle_array.inject(:+)
      @ss += cycle_array.map {|x| x*x}.inject(:+)
      @count += cycle_array.size
    end

    @ct = @mean*@mean / @count.to_f
    @mean /= @count.to_f

    effFacts = []
    ps_block[:keys].each_with_index do |key, index|
      effFact = {}
      effFact[:name] = index
      effFact[:results] = {}

      ps_block[:ps].each do |ps|
        effFact[:results][ps[:v][index]] ||= []
        effFact[:results][ps[:v][index]] += ps[:result]
      end

      effFact[:effect] = 0.0
      effFact[:results].each_value do |v|
        effFact[:effect] += (v.inject(:+)**2).to_f / v.size
      end
      effFact[:effect] -= @ct
      effFact[:free] = 1
      effFacts << effFact
    end

    @s_e = @ss - (@ct + effFacts.inject(0) {|sum,ef| sum + ef[:effect]})
    @e_f = @count - 1
    effFacts.each do |ef|
      @e_f -= ef[:free]
    end

    @e_f = 1 if @e_f == 0 # TODO
    @e_v = @s_e / @e_f
    effFacts.each do |fact|
      if fact[:effect] <= 0.0
        fact[:f_value] = 0.0
      elsif @e_v == 0.0
        fact[:f_value] = fact[:effect]
      else
        fact[:f_value] = fact[:effect] / @e_v
      end
    end

    # effFacts
    effFacts.map{|fact| fact[:f_value]}
  end

  private
  def self.cycles(ps)
    ps.runs.map {|run| run.analyses.only("result").first.result["Cycles"]}
  end
end

if $0 == __FILE__
  
  # ps_block = {  keys: ["x", "y"],
  #               ps: [
  #                     {v: [-5.5,-5.5], result: [ 0.919123, 1.208341, 0.923663, 1.022789, 1.138628 ]},
  #                     {v: [-5.5,-4.5], result: [ 1.157638, 1.123510, 1.151364, 0.966503, 1.043049 ]},
  #                     {v: [-4.5,-5.5], result: [ 0.954927, 1.530289, 1.063220, 1.148652, 1.146276 ]},
  #                     {v: [-4.5,-4.5], result: [1.2972571, 1.203748, 1.100992, 1.056991, 1.213790 ]}
  #                   ]
  #             }
  ps_block = {  keys: ["x", "y"],
                ps: [
                      {v: [-5.5,-5.5], result: [ 0.0, 0.0, 0.0, 0.0, 0.0 ]},
                      {v: [-5.5,-4.5], result: [ 0.0, 0.0, 0.0, 0.0, 0.0 ]},
                      {v: [-4.5,-5.5], result: [ 0.0, 0.0, 0.0, 0.0, 0.0 ]},
                      {v: [-4.5,-4.5], result: [ 0.0, 0.0, 0.0, 0.0, 0.0 ]}
                    ]
              }

  pp FTest.eff_facts(ps_block)

binding.pry
end
