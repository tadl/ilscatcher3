class Item
	include ActiveModel::Model
	require 'open-uri'
	attr_accessor :id, :loc, :author, :title, :abstract, :contents, :image, :format_type, :record_year, :publisher, :publication_place, :isbn, :physical_description, :eresource, :copies, :copies_on_shelf

	def initialize args
		if args['id']
			if args['title'] && !args['copies']
				args.delete_if { |k, v| v.blank? }
				args.each do |k,v|
        	instance_variable_set("@#{k}", v) unless v.nil?
      	end
      else
    		details = get_details(args['id'], args['loc'])
      end
    else
      return nil
    end
  end

  	def check_trailer
  		fetch_trailer = JSON.parse(open('https://trailer-tank.herokuapp.com/main/get_trailer.json?id=' + self.id, {:read_timeout => 1}).read) rescue nil
  		if fetch_trailer.nil? || !fetch_trailer['message'] || fetch_trailer['message'] == 'error'
  			trailer = nil
  		else
  			trailer = fetch_trailer['message']
  		end
  		return trailer
  	end

  	def get_details(id, loc)
  		if loc
  			loc_url = '?locg=' + loc
  		else
  			loc_url = '?locg=22'
  		end
  		url = 'https://mr-v2.catalog.tadl.org/eg/opac/record/' + id + loc_url
  		agent = Mechanize.new
  		page = agent.get(url)
  		page = page.parser
  		item_details = ''
  		page.css('#main-content').each do |detail|
  			item_details = {
  			:author => detail.at_css(".rdetail_authors_div").try(:text).try(:gsub, /\n/, "").try(:strip),
			:title => detail.at_css("#rdetail_title").text,
			:abstract => detail.at('td:contains("Summary, etc.:")').try(:next_element).try(:text).try(:strip),
			:contents => detail.at('td:contains("Formatted Contents Note:")').try(:next_element).try(:text).try(:strip),
			:id => id,
			:availability_scope => detail.css('meta[@property="seller"]').map {|i| i.attr('content')}, 
			:copies_available => detail.css('meta[@property="offerCount"]').map {|i| i.attr('content')},
			:copies_total => clean_totals_holds(detail.at('h2:contains("Current holds")').try(:next_element).try(:text))[1],
			:holds => clean_totals_holds(detail.at('h2:contains("Current holds")').try(:next_element).try(:text))[0],
			:eresource => detail.at('p.rdetail_uri').try(:at, 'a').try(:attr, "href"),
			:image => detail.at_css('#rdetail_image').try(:attr, "src").try(:gsub, /^\//, "https://catalog.tadl.org/").try(:gsub, /medium/, "large"),
			:format_type => detail.at('div#rdetail_format_label').try(:text).try(:strip),
			:format_icon => detail.at('div#rdetail_format_label').try(:at, 'img').try(:attr, "src"),
			:record_year => detail.search('span[@property="datePublished"]').try(:text),
			:publisher => detail.search('span[@property="publisher"]').search('span[@property="name"]').try(:text).try(:strip),
			:publication_place => detail.search('span[@property="publisher"]').search('span[@property="location"]').try(:text).gsub(':','').try(:strip),
			:isbn => detail.css('span[@property="isbn"]').map {|i| i.text},
			:physical_description => detail.at('li#rdetail_phys_desc').try(:at, 'span.rdetail_value').try(:text),
			:related => detail.css('.rdetail_subject_value').to_s.split('<br>').reverse.drop(1).reverse.map { |i| clean_related(i)}.uniq,
  			}
  		end
  		item_details.delete_if { |key, value| value.blank? }
  		item_details.each do |k,v|
        	instance_variable_set("@#{k}", v) unless v.nil?
      	end
      	copy_details(id, loc, page)
  	end

  	def copy_details(id, loc, page)
  		if !page
  			if loc
  				loc_url = '?locg=' + loc
  			else
  				loc_url = '?locg=22'
  			end
  			url = 'https://mr-v2.catalog.tadl.org/eg/opac/record/' + id + loc_url
  			agent = Mechanize.new
  			page = agent.get(url)
  			page = page.parser
  		end

  		copies = Array.new
  		page.css('.copy_details_offers_row').each do |copy|
  			copy = {
  				:location => copy.css('span[@property="name"]').try(:text),
  				:call_number => copy.css('span[@property="sku"]').try(:text),
  				:shelving_location => copy.css('td[@property="availableAtOrFrom"]').try(:text),
  				:status => copy.at_css('td[@property="availableAtOrFrom"]').next.next.try(:text),
  				:due_date => copy.at_css('td[@property="availableAtOrFrom"]').next.next.next.next.try(:text),
  			}
  			copies.push(copy)
  		end

    	copies_on_shelf = Array.new
    	copies.each do |copy|
      		if copy[:status] == "Available"
        		copies_on_shelf.push(copy)
      		end
      	
      		if copy[:status] == "Reshelving"
        		copy[:shelving_location] = copy[:shelving_location] + " (Reshelving)"
        		copies_on_shelf.push(copy)
      		end  
    	end
    	instance_variable_set("@copies", copies)
    	instance_variable_set("@copies_on_shelf", copies_on_shelf)
  	end

  	def goodreads
      if self.format_type == 'Language material' || 'Manuscript language material' || 'Nonmusical sound recording'
        fetch_review = JSON.parse(open('https://reviewcatcher.herokuapp.com/?isbn=' + self.isbn, {:read_timeout => 1}).read) rescue nil
        return fetch_review
      end
  	end

  	def clean_related(subject)
 		subject.gsub!(/\n/, "")
  		subject.gsub!(/<[^<>]*>/, "")
  		subject.to_s
  		subject.split('&gt;')
  	end

  	def clean_totals_holds(text)
  		totals = text.split('with') rescue nil
  		total_holds = totals[0].gsub('current holds','').strip rescue nil
  		total_copies = totals[1].gsub('total copies.','').strip rescue nil
  		return total_holds, total_copies
  	end

    def marc
      url = 'https://mr-v2.catalog.tadl.org/eg/opac/record/' + self.id + '?expand=marchtml#marchtml'
      agent = Mechanize.new
      page = agent.get(url)
      marc_record = page.parser.at_css('.marc_table').to_s.gsub(/\n/,'').gsub(/\t/,'')
      return marc_record
    end


    def create_params
      hash = Hash.new
      self.instance_variables.each {|v| hash[v.to_s.delete("@")] = self.instance_variable_get(v)}
      return hash
    end

end
