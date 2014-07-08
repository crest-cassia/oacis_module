require_relative '../models/doe_result'

class DOEResultController #< ApplicationController

	# def create(sim, ps_block_with_id_set, result_block)
	# 	logon_doe_DB

	# 	result = DOEResult.create!(
 #      simulator: sim,
 #      module_name: "doe",
 #      block: ps_block_with_id_set,
 #      results: result_block
	# 	)

 #    result.save!

	# 	leave_doe_DB
	# end

  def create(sim, ps_block, id_list, result_block)
    logon_doe_DB

    result = DOEResult.create!(
      simulator: sim,
      module_name: "doe",
      id_list: id_list,
      block: ps_block,
      results: result_block
    )

    result.save!

    leave_doe_DB
  end

	def destroy
  end

  # def duplicate(sim, check_block)
  #   # logon_doe_DB

  #   # v_set = []
  #   # check_block[:ps].each do |ps|
  #   #   parameter_set = {}
  #   #   ps[:v].each_with_index do |value, index|
  #   #     parameter_set[check_block[:keys][index]] = value
  #   #   end
  #   #   v_set << parameter_set
  #   # end
  #   # query = {"$and" => [{"simulator" => sim}, {"block.v_set"=> v_set}]}
  #   id_list = []
  #   check_block[:ps].each do |ps|
  #     parameter_set = {}
  #     ps[:v].each_with_index do |value, index|
  #       parameter_set[check_block[:keys][index]] = value
  #     end
  #     v_set << parameter_set
  #   end
  #   query = {"$and" => [{"simulator" => sim}, {"id_list"=> id_list}]}

  #   logon_doe_DB

  #   ret = DOEResult.where(query).count

  #   leave_doe_DB

  #   ret > 0
  # end

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