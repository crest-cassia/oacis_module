require_relative '../models/doe_result'

class DOEResultController #< ApplicationController

	def create(parameter_set_block, result_block)
		Mongoid::sessions.clear
		Mongoid::Config.load!('../doe_develop.yml')

		DOEResult.create(
			module_name: "doe",
  		block: parameter_set_block,
  		results: result_block
		)

		Mongoid::sessions.clear
		Mongoid::Config.load!(File.join(Rails.root, 'config/mongoid.yml'))
	end

	def destroy
  end

  def duplicate
  end

  def show
  end  
end