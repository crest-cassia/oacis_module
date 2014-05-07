require_relative '../models/doe_result'

class DOEResultController #< ApplicationController

	def create(parameter_set_block, result_block)
		logon_doe_DB

		DOEResult.create(
			module_name: "doe",
  		block: parameter_set_block,
  		results: result_block
		)

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
end