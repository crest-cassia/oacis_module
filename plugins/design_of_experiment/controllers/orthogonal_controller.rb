require_relative '../models/orthogonal'
require 'pry'

class OrthogonalController #< ApplicationController

  #
	def create(sim, row)
		logon_doe_DB
		o_table = Orthogonal.create!(simulator: sim, row: row)
    o_table.save!
		leave_doe_DB
	end

  #
	def update(sim, name, bit)
		logon_doe_DB
    condition = {"$and" => [{"simulator" => sim}, {"row.#{name}.bit" => bit}]}
		# orthogonal_rows = Orthogonal.where("row.#{name}.bit" => bit)
    orthogonal_rows = Orthogonal.where(condition)
		if !orthogonal_rows.nil?
			orthogonal_rows.each do |orthogonal_row|
				tmp = orthogonal_row.row
				tmp["#{name}"]["bit"] = "0#{bit}"
				orthogonal_row.update_attributes!(row: tmp)
        orthogonal_row.save
			end
		end
		leave_doe_DB
	end

  # 
	def destroy
  end

  #
  def add_copied_table(sim, name)
    logon_doe_DB

    copied_rows = []
    Orthogonal.each do |o_row|
      if o_row["simulator"] == sim
        copied_row = o_row.dup.row
        tmp = o_row.dup.row
        tmp[name]["bit"] = "0#{tmp[name]["bit"]}"
        o_row.update_attributes!(row: tmp)
        o_row.save

        copied_row[name]["bit"] = "1#{copied_row[name]["bit"]}"
        copied_row[name]["value"] = nil
        copied_rows << copied_row
      end
    end

    copied_rows.each do |r|
      o_table = Orthogonal.create!(simulator: sim, row: r)
      o_table.save!
    end

    leave_doe_DB
  end

  #
  def assign_parameter_to_table(sim, name, corresponds)
    logon_doe_DB

    corresponds.each do |cor|
      condition = {"$and" => [{"simulator" => sim}, {"row.#{name}.bit" => cor["bit"]}]}
      orthogonal_rows = Orthogonal.where(condition)
      orthogonal_rows.count
      if !orthogonal_rows.nil?
        orthogonal_rows.each do |o_row|
          tmp = o_row.row
          if tmp[name]["bit"] == cor["bit"]
            tmp[name]["value"] = cor["value"]
            o_row.update_attributes!(row: tmp)
            o_row.save
          end
        end
      end
    end
    
    leave_doe_DB
  end


  # 
  def find_rows(sim, param_condition)
  	logon_doe_DB
    condition = {"$and" => [{"simulator" => sim}, param_condition]}
  	ret = Orthogonal.where(condition)
    ret.count

  	leave_doe_DB

  	return ret
  end

  #
  def get_size(sim)
    logon_doe_DB
    size = Orthogonal.where("simulator" => sim).count
    leave_doe_DB

    return size
  end

  # 
  def duplicate_check(sim, rows)
  	logon_doe_DB

  	checked_rows = {:new => [], :duplicate => []}

  	rows.each do |row|
  		condition = {"$and" => [{"simulator" => sim}]}
  		row.each do |name, corr|
  			# condition["row.#{name}.value"] = corr["value"]
        condition["$and"] << {"row.#{name}.value" => corr["value"]}
  		end
  		orthogonal_row = Orthogonal.where(condition)
  		if orthogonal_row.count > 0
  			checked_rows[:duplicate] += orthogonal_row.map{|ort| ort.row}
  		else
  			checked_rows[:new] << row
  		end
  	end
		
		leave_doe_DB

		checked_rows
  end

  #
  def get_parameter_correspond(sim, name)
    logon_doe_DB
    rows = []
    Orthogonal.where("simulator" => sim).each do |doc|
      rows << doc["row.#{name}"]
    end
    leave_doe_DB
    return rows.select{|r| !r["value"].nil? }.uniq
  end


  # 
  def show
  end

  def test_query
    logon_doe_DB
    binding.pry
    leave_doe_DB
  end

  private
  def logon_doe_DB
  	Mongoid::sessions.clear
		Mongoid::Config.load!('./doe_develop.yml')
  end

  def leave_doe_DB
  	Mongoid::sessions.clear
		Mongoid::Config.load!(File.join(Rails.root, 'config/mongoid.yml'))
  end
end