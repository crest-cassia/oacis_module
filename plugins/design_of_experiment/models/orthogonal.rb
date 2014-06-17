class Orthogonal
	include Mongoid::Document
  include Mongoid::Timestamps

  
  field :row, type: Hash
  # field :block, type: Hash # block is collection of parameter set
  field :simulator, type: String

  index({ status: 1 }, { name: "orthogonal_index" })

  attr_accessible :row, :simulator



  private
  def validate_orthogonal_rows

  end

  #
  def self.find_orthogonal_rows(simulator, sim_row_hash)
  end
  
end