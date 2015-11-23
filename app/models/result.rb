class Result
	include ActiveModel::Model
	attr_accessor :title, :author, :availability, :copies_available, :copies_total,
								:id, :eresource, :image, :abstract, :contents, :format_icon,
								:format_type, :record_year, :call_number, :publisher,
								:publication_place, :isbn, :physical_description,
								:all_copies_available, :all_copies_total, :loc_copies_total,
								:loc_copies_available, :author_other, :subjects, :genres, :series, :holdings

	def initialize args
    args.each do |k,v|
    		instance_variable_set("@#{k}", v)
    end
  end

end
