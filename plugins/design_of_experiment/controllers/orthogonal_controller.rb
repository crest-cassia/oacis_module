require_relative '../models/orthogonal'

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

  def duplicate
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

  def find_correspond(condition)
  	# condition = {name => "bit string"}


  end

end