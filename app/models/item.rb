class Item
	include ActiveModel::Model
	require 'open-uri'
	attr_accessor :id, :loc, :author, :title, :abstract, :contents, :record_id, :image, :format, :record_year, :publisher, :publication_place, :isbn, :physical_description, :eresource

	def initialize args
		if args['id']
			if args['title']
				args.each do |k,v|
        			instance_variable_set("@#{k}", v) unless v.nil?
      			end
      		else
    			details = all_details(args['id'], args['loc'])
  				details.each do |k,v|
        			instance_variable_set("@#{k}", v) unless v.nil?
      			end
      		end
      	else
      		return nil
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
  		fetch_trailer = JSON.parse(open('https://trailer-tank.herokuapp.com/main/get_trailer.json?id=' + self.id).read) rescue nil
  		if !fetch_trailer['message'] || fetch_trailer['message'] == 'error'
  			trailer = nil
  		else
  			trailer = fetch_trailer['message']
  		end
  		return trailer
  	end

  	def all_details(record_id, loc)
  		if loc
  			loc_url = '?locg=' + loc
  		else
  			loc_url = '?locg=22'
  		end
  		url = 'https://mr.tadl.org/eg/opac/record/' + record_id + loc_url
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
			:record_id => record_id,
			:availability_scope => detail.css('meta[@property="seller"]').map {|i| i.attr('content')}, 
			:copies_available => detail.css('meta[@property="offerCount"]').map {|i| i.attr('content')},
			:copies_total => clean_totals_holds(detail.at('h2:contains("Current holds")').try(:next_element).try(:text))[1],
			:holds => clean_totals_holds(detail.at('h2:contains("Current holds")').try(:next_element).try(:text))[0],
			:eresource => detail.at('p.rdetail_uri').try(:at, 'a').try(:attr, "href"),
			:image => detail.at_css('#rdetail_image').try(:attr, "src").try(:gsub, /^\//, "https://catalog.tadl.org/").try(:gsub, /medium/, "large"),
			:format => detail.at('div#rdetail_format_label').text.strip,
			:format_icon => detail.at('div#rdetail_format_label').at('img').try(:attr, "src"),
			:record_year => detail.search('span[@property="datePublished"]').try(:text),
			:publisher => detail.search('span[@property="publisher"]').search('span[@property="name"]').try(:text).try(:strip),
			:publication_place => detail.search('span[@property="publisher"]').search('span[@property="location"]').try(:text).gsub(':','').try(:strip),
			:isbn => detail.css('span[@property="isbn"]').map {|i| i.text},
			:physical_description => detail.at('li#rdetail_phys_desc').try(:at, 'span.rdetail_value').try(:text),
			:related => detail.css('.rdetail_subject_value').to_s.split('<br>').reverse.drop(1).reverse.map { |i| clean_related(i)}.uniq,
  			}
  		end
  		item_details.each do |k,v|
        	instance_variable_set("@#{k}", v) unless v.nil?
      	end
  	end

  	def copy_details
  	end

  	def marc_record
  	end

  	def goodread_review

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

end
