require_relative '../model/orthogonal'

class OrthogonalController #< ApplicationController

	def create(corresponds)
		login

		Orthogonal.create(
  		corresponds: corresponds
		)

		leave
	end

	def update(corresponds)
		login
		Orthogonal.update(
			
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
  	Mongoid::sessions.clear
		Mongoid::Config.load!('../doe_rdevelop.yml')
  end

  def leave
  	Mongoid::sessions.clear
		Mongoid::Config.load!(File.join(Rails.root, 'config/mongoid.yml'))
  end

end