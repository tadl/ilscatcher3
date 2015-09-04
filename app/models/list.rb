class List
	include ActiveModel::Model
	attr_accessor :list_id, :title, :description, :shared, :default

	def initialize args
    args.each do |k,v|
    		instance_variable_set("@#{k}", v) unless v.nil?
    end
  end

  def create_params
  	hash = Hash.new
  	self.instance_variables.each {|v| hash[v.to_s.delete("@")] = self.instance_variable_get(v)}
  	return hash
  end
end
