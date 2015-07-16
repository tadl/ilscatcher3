class Hold
	include ActiveModel::Model
	attr_accessor :title, :author, :record_id, :hold_id, :hold_status, :queue_status, :queue_state, :pickup_location, :task

	def initialize args
    	args.each do |k,v|
    		instance_variable_set("@#{k}", v) unless v.nil?
    	end
  	end

  	def create_params(task)
  		hash = Hash.new
  		self.instance_variables.each {|v| hash[v.to_s.delete("@")] = self.instance_variable_get(v)}
      hash['task'] = task
  		return hash
  	end

    def ready
      self.queue_status.start_with?("Available")
    end
end