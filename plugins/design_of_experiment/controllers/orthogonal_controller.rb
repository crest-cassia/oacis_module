require_relative '../models/orthogonal'

class OrthogonalController #< ApplicationController

	def create(row)
		login

		Orthogonal.create(
  		row: row
		)

		leave
	end

	def update(row)
		login
		Orthogonal.update(
			row: row
		)
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
binding.pry
  	Mongoid::sessions.clear
		Mongoid::Config.load!('./doe_develop.yml')
  end

  def leave
  	Mongoid::sessions.clear
		Mongoid::Config.load!(File.join(Rails.root, 'config/mongoid.yml'))
  end

end