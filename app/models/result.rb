class Result
	include ActiveModel::Model
	attr_accessor :title, :author, :availability, :copies_available, :copies_total, :record_id, :eresource, :image, :abstract, :contents, :format_icon, :format_type, :record_year, :call_number

	def initialize args
    	args.each do |k,v|
      		instance_variable_set("@#{k}", v) unless v.nil?
    	end
  	end
end
