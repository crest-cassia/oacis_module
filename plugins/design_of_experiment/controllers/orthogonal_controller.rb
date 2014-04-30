require_relative '../models/orthogonal'

class OrthogonalController #< ApplicationController

	def create(row)
		login
		Orthogonal.create(row: row)
		leave
	end

	def update(name, bit)
		login
		orthogonal_rows = Orthogonal.where("row.#{name}.bit" => bit)
		if !orthogonal_rows.nil?
			orthogonal_rows.each do |orthogonal_row|
				tmp = orthogonal_row.row
				tmp["#{name}"]["bit"] = "0#{bit}"
				orthogonal_row.update_attributes!(row: tmp)
			end
		end
		leave
	end

	def destroy
  end

  def duplicate
  end

  def show
  end

  private
  def login
  	Mongoid::sessions.clear
		Mongoid::Config.load!('./doe_develop.yml')
  end

  def leave
  	Mongoid::sessions.clear
		Mongoid::Config.load!(File.join(Rails.root, 'config/mongoid.yml'))
  end

  def find_correspond(condition)
  	# condition = {name => "bit string"}


  end

end