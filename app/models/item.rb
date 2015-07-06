class Item
include ActiveModel::Model
	attr_accessor :title, :full_summary, :full_contents, :holds, :id 

	def initialize args
    	args.each do |k,v|
      		instance_variable_set("@#{k}", v) unless v.nil?
    	end
  	end

  	def get_details
  		details = JSON.parse(open('http://ilscatcher2.herokuapp.com/items/details?record=' + self.id).read)
  		item = details['item_details']
  		copies_on_shelf = details['copies_on_shelf']
  		copies_all = details['copies']
  		return item, copies_on_shelf, copies_all
  	end

  	def check_trailer
  		fetch_trailer = JSON.parse(open('https://trailer-tank.herokuapp.com/main/get_trailer.json?id=' + self.id).read)
  		if !fetch_trailer['message'] || fetch_trailer['message'] == 'error'
  			trailer = nil
  		else
  			trailer = fetch_trailer['message']
  		end
  		return trailer
  	end 

end
