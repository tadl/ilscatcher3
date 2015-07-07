class Result
	include ActiveModel::Model
	attr_accessor :title, :author, :availability, :copies_available, :copies_total, :id, :eresource, :image, :abstract, :contents, :format_icon, :format_type, :record_year, :call_number, :publisher, :publication_place, :isbn, :physical_description

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
