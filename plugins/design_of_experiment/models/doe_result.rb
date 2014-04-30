class DOEResult
	include Mongoid::Document
  include Mongoid::Timestamps


  field :module_name, type: String
  field :block, type: Hash # block is collection of parameter set
  field :results, type: Hash

  index({ status: 1 }, { name: "doe_result_index" })

  # validates : validate_doe_results, on: :create
  attr_accessible :module_name, :block, :results



  private
  def validate_doe_results
  end

  def self.find_identical_doe_result(block_ids)
  end

end