class Orthogonal
	include Mongoid::Document
  include Mongoid::Timestamps

  
  field :corresponds, type: Hash
  # field :block, type: Hash # block is collection of parameter set
  

  index({ status: 1 }, { name: "orthogonal_index" })

  # validates : validate_doe_results, on: :create
  attr_accessible :corresponds



  private
  def validate_orthogonal_rows
  end

  #
  def self.find_orthogonal_rows    
  end

  
end