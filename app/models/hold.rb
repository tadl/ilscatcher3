class Hold
	include ActiveModel::Model
	attr_accessor :title, :author, :record_id, :hold_id, :hold_status, :queue_status, :queue_state, :pickup_location

	def initialize args
    args.each do |k,v|
    		instance_variable_set("@#{k}", v) unless v.nil?
    end
  end
end