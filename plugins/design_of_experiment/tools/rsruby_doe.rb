require 'rsruby'
require 'rsruby/dataframe'


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
      RSRuby.instance.reset_cache
      # @r = RSRuby.instance
      @r.library('DoE.base')
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
      # @r.eval_R("write.csv(parameterSet, \"set.csv\", quote=F, row.names=F)")

      parameter_sets = @r.parameterSet
    end 
  end

  #
  def self.aov(x1, x2, x3, y1, y2, y3)
    # signif_code = {0.001=>"***", 0.01=>"**", 0.05=>"*", 0.1=>"."}
    RSRuby.instance.reset_cache
    r_aov = RSRuby.instance
    g1,g2=0,1
    r_aov.eval_R("x1<-#{x1}")
    r_aov.eval_R("x2<-#{x2}")
    r_aov.eval_R("x3<-#{x3}")

    r_aov.eval_R("y1<-c(#{y1.join(",")})")
    r_aov.eval_R("y2<-c(#{y2.join(",")})")
    r_aov.eval_R("y3<-c(#{y3.join(",")})")
    
    r_aov.eval_R("g1<-#{g1}")
    r_aov.eval_R("g2<-#{g2}")

    r_aov.eval_R("data1<-data.frame(g=g1,rbind(merge(x1,y1),merge(x2,y2)))")
    r_aov.eval_R("data2<-data.frame(g=g2,rbind(merge(x2,y2),merge(x3,y3)))")
    r_aov.eval_R("data<-data.frame(rbind(data1,data2))")
    # r_aov.eval_R("reslm<-lm(y~x*factor(g), data=data)")
    # r_aov.eval_R("res<-summary.aov(reslm)")
    r_aov.eval_R("res<-summary.aov(lm(y~x*factor(g), data=data))")

    if r_aov.res["Pr(>F)"][2] < 0.05
      # r_aov.eval_R("rm(reslm)")
      # r_aov.eval_R("rm(res)")
      return true
    else
      # r_aov.eval_R("rm(reslm)")
      # r_aov.eval_R("rm(res)")
      return false
    end
  end
  #
  def self.cor_plot(headers, data, num=1)
      RSRuby.instance.reset_cache
      r = RSRuby.instance
      r.library('psych')
      headers.each.with_index{|k, i|
        r.eval_R("#{k}<-c(#{data[i].join(",")})")
      }
      r.eval_R("data<-data.frame(#{headers.join(",")})")
      r.eval_R("corData<-cor(data)")

      binding.pry
      
      r.eval_R("cor.plot(corData)")
      system("mv Rplots.pdf Rplots_#{num}.pdf")
      # sel<-data.frame(cw[1:7],cw[14],cw[16],cw[18])
      # z<-cor(sel)
      # cor.plot(z, "./plot_test.pdf")
    end
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

def rsruby_test2
  require 'pry'
  include Doe

  # @r = RSRuby.instance

  x1,x3,x5,x7=1000,3000,5000,7000

  y1=[1925, 1981, 2027, 2183, 2196, 2167, 2169, 2174, 
      2198, 2149, 2180, 2119, 1925, 1972, 2027, 2135, 
      2154, 2112, 2038, 2027, 2041, 1771, 1798, 1792, 
      2155, 2179, 2132, 1988, 1979, 2027, 1869, 1852, 
      1861, 2154, 2172, 2130, 1988, 1979, 2027, 2135, 
      2157, 2111, 1925, 1972, 2027, 2110, 2109, 2102, 
      1925, 1972, 2027, 1988, 1979, 1988]
  y3=[3747, 3725, 3732, 3373, 3317, 3359, 4843, 4832,
      4845, 3524, 3512, 3562, 2611, 2628, 2617, 2807,
      2814, 2802, 4592, 4614, 4605, 2916, 2848, 2814, 
      3052, 3105, 3071, 2604, 2626, 2619, 2689, 2701, 
      2685, 3533, 3574, 3599, 3518, 3533, 3449, 2488, 
      2496, 2486, 2824, 2846, 2831, 5039, 5086, 5064, 
      2698, 2699, 2701, 2544, 2571, 2571]
  y5=[5928, 6195, 5829, 5174, 5250, 5161, 7759, 7708, 
      7752, 5854, 5968, 5928, 3999, 3939, 3937, 4375, 
      4334, 4357, 7356, 7350, 7350, 4884, 4776, 4691, 
      4873, 4851, 4822, 3711, 3699, 3706, 4039, 4009, 
      4001, 5495, 5543, 5571, 5339, 5341, 5306, 3549, 
      3550, 3552, 4393, 4066, 4200, 8310, 8321, 8310, 
      3877, 3911, 3849, 3691, 3680, 3692]
  y7=[8058, 8135, 8724, 7376, 7738, 7443, 10855, 10857, 
      10800, 8829, 9058, 8885, 5643, 5539, 5600, 5968, 
      5933, 5924, 10228, 10184, 10167, 6953, 6841, 6976, 
      8198, 8141, 7724, 5062, 5083, 5120, 5324, 5320, 
      5258, 7897, 8064, 7888, 7178, 7105, 7150, 4878, 
      4902, 4914, 6375, 6426, 6396, 11611, 11637, 11609, 
      5592, 5379, 5600, 5042, 5027, 5021]
  

  p "#{x3}:#{x5} ~ #{x5}:#{x7}"
  p res2 = Doe.aov(x3, x5, x7, y3, y5, y7)
  # p @r.res["Pr(>F)"]

  p "#{x1}:#{x3} ~ #{x3}:#{x5}"
  p res = Doe.aov(x1, x3, x5, y1, y3, y5)
  # p @r.res["Pr(>F)"]
  
  binding.pry
end

def test_plot_save

  r=RSRuby.instance
  r.library('psych')
  r.eval_R("cw<-read.csv(\"out_result.csv\")")
  r.eval_R("sel<-data.frame(cw[1:7],cw[14],cw[16],cw[18])")
  r.eval_R("z<-cor(sel)")

  filename="test"

  # r.eval_R("postscript(\"#{filename}.eps\")")
  r.eval_R("pdf(\"#{filename}.pdf\")")
  # r.eval_R("jpeg(\"#{filename}.jpg\")")

  r.eval_R("cor.plot(z)")

  r.eval_R("dev.off()")
  # r.eval_R("")

end


if __FILE__ == $0
  require 'pry'

  # rsruby_test2
  test_plot_save

end