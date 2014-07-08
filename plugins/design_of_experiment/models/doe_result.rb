class DOEResult
	include Mongoid::Document
  include Mongoid::Timestamps


  field :module_name, type: String
  field :simulator, type: String
  field :id_list, type: Hash
  field :block, type: Hash # block is collection of parameter set
  field :results, type: Hash
  

  # index({ status: 1 }, { name: "doe_result_index" })
  # index({ id_list: 1 }, { unique: true, name: "doe_block_index" })#background: true

  attr_accessible :module_name, :simulator, :id_list, :block, :results


  private
  def validate_doe_results
  end

  def self.find_identical_doe_result(simulator, block_hash)
    # self.where(:simulator => simulator, :block => block_hash ).first
  end

end