require_relative '../models/orthogonal'
require 'pry'

class OrthogonalController #< ApplicationController

	def create(row)
		logon_doe_DB
		Orthogonal.create(row: row)
		leave_doe_DB
	end

	def update(name, bit)
		logon_doe_DB
		orthogonal_rows = Orthogonal.where("row.#{name}.bit" => bit)
		if !orthogonal_rows.nil?
			orthogonal_rows.each do |orthogonal_row|
				tmp = orthogonal_row.row
				tmp["#{name}"]["bit"] = "0#{bit}"
				orthogonal_row.update_attributes!(row: tmp)
			end
		end
		leave_doe_DB
	end

	def destroy
  end

  def find(condition)
  	logon_doe_DB
  	ret = Orthogonal.where(condition)
  	leave_doe_DB
  	ret 
  end

  # 
  def duplicate_check(rows)
  	logon_doe_DB

  	checked_rows = {:new => [], :dulicate => []}

  	rows.each do |row|
  		condition = {}
  		row.each do |name, corr|
  			condition["row.#{name}.value"] = corr["value"]
  		end
  		orthogonal_row = Orthogonal.where(condition)
  		if orthogonal_row.count > 0
  			checked_rows[:dulicate] << row
  		else
  			checked_rows[:new] << row
  		end
  	end
		
		leave_doe_DB

		checked_rows
  end

  def show
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