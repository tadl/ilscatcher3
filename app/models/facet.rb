class Facet 
	include ActiveModel::Model
	attr_accessor :type, :type_raw, :subfacets
	
	def initialize args
    	args.each do |k,v|
      		instance_variable_set("@#{k}", v) unless v.nil?
    	end
    end
end
