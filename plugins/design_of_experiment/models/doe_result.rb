class DOEResult
	include Mongoid::Document
  include Mongoid::Timestamps


  field :module_name, type: String
  field :block, type: Hash # block is collection of parameter set
  field :results, type: Hash
  field :simulator, type: String

  index({ status: 1 }, { name: "doe_result_index" })

  attr_accessible :module_name, :simulator, :block, :results


  private
  def validate_doe_results
  end

  def self.find_identical_doe_result(simulator, block_hash)
    # self.where(:simulator => simulator, :block => block_hash ).first
  end

end