class Result
	include ActiveModel::Model
	attr_accessor :title, :author, :availability, :copies_available, :copies_total,
								:id, :eresource, :image, :abstract, :contents, :format_icon,
								:format_type, :record_year, :call_number, :publisher,
								:publication_place, :isbn, :physical_description,
								:all_copies_available, :all_copies_total, :loc_copies_total,
								:loc_copies_available, :author_other, :subjects, :genres, :series

	def initialize args
    args.each do |k,v|
    		instance_variable_set("@#{k}", v)
    end
  end

  def create_params
  	hash = Hash.new
  	self.instance_variables.each {|v| hash[v.to_s.delete("@")] = self.instance_variable_get(v)}
  	return hash
  end
end
