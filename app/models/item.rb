class Item
include ActiveModel::Model
	attr_accessor :title, :full_summary, :full_contents, :holds, 

	def initialize args
    	args.each do |k,v|
      		instance_variable_set("@#{k}", v) unless v.nil?
    	end
  	end 

end
