class Checkout
	include ActiveModel::Model
	attr_accessor :title, :author, :record_id, :checkout_id, :renew_attempts, :due_date, :iso_due_date, :barcode, :renew

	def initialize args
    	args.each do |k,v|
    		instance_variable_set("@#{k}", v) unless v.nil?
    	end
  	end

  	def create_params(renew)
  		hash = Hash.new
  		self.instance_variables.each {|v| hash[v.to_s.delete("@")] = self.instance_variable_get(v)}
      hash['renew'] = renew
  		return hash
  	end

    def ready
      self.queue_status.start_with?("Available")
    end
end