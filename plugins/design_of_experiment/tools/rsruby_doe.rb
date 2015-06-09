require 'rsruby'


module Doe
  #
  class DoeSearch
    #
    def initialize(parameter_defnitions)
      @r = RSRuby.instance
      @r.library('DoE.base')
      @parameter_defnitions = parameter_defnitions
    end

    # 
    def create_parameter_set(set)

      # set data 
      set.each{|k,v| @r.eval_R("#{k}<-c(#{v.join(",")})") }
      const_list = @parameter_defnitions["consts"].map{|k| "#{k}=#{k}" }.join(",")

      # crate OA table
      @r.eval_R("oaTable<-oa.design(factor.names=list(#{const_list}),seed=0)")
      
      # target parameters are set to data.frame
      @parameter_defnitions["targets"].each{|k| @r.eval_R("#{k}Frame <- data.frame(#{k}=#{k})")}

      # merge
      if @parameter_defnitions["targets"].size >= 2
        t = @parameter_defnitions["targets"]
        t.each_with_index{|k, i|
          if i==0
            next
          elsif i==1
            @r.eval_R("dataFrames <- merge(#{t[i-1]}Frame, #{k}Frame)")  
          else
            @r.eval_R("dataFrames <- merge(dataFrames, #{k}Frame)")
          end          
        }        
      else
        @parameter_defnitions["targets"].each{|k|
          @r.eval_R("dataFrames <- #{k}Frame")
        }
      end
      @r.eval_R("parameterSet <- merge(oaTable, dataFrames)")
      
      # save csv file
      @r.eval_R("write.csv(parameterSet, \"set.csv\", quote=F, row.names=F)")

      parameter_sets = @r.parameterSet
    end

  end
end



def rsruby_test
  require 'pry'
  r = RSRuby.instance
  r.library('DoE.base')

  agent_generation_point = ["z1", "z2", "z3", "z4", "z5", "z6", "o5"]
  population=[70, 500, 1000, 1500, 2000, 2500, 5000, 7500, 10000]
  
  agent_generation_point.each{|point| r.eval_R("#{point}<-c(0:2)") }
  r.eval_R("population<-c(#{population.join(",")})")

  r.eval_R("oaTable<-oa.design(factor.names=list(z1=z1,z2=z2,z3=z3,z4=z4,z5=z5,z6=z6,o5=o5),seed=1)")
  r.eval_R("pop_frame <- data.frame(population=population)")


  binding.pry
end

#
module CrowdWalkConvertCSV

  def self.csv_modified(filename)
    require 'pry'
    array = CSV.read(filename)
    converted = []

    head = array[0]
    converted << ["z1","z2","z3","z4","z5","z6","o5",70,500,1000,1500,2000,2500,5000,7500,10000]
    array.each_with_index{|row, i|
      next if i == 0

      origins = row.slice(0..20)
      pops = row.slice(21..-1).map{|s| s.to_i}
      convert_origins = origins.each_slice(3).map{|s| judge(s.join("")) }
      converted << convert_origins+pops
    }

    
    CSV.open("./convert_crowdwalk.csv", "w"){|row|
      converted.each{|r| row << r }
    }
  end

  #
  def self.judge(str)
    case str
    when "001"
      return 2
    when "010"
      return 1
    when "100"
      return 0
    else
      return nil        
    end
  end
end

if __FILE__ == $0
  require 'pry'

  rsruby_test

end