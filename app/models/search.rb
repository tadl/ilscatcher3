class Search
	require 'open-uri'
	include ActiveModel::Model
	attr_accessor :query, :sort, :qtype, :format, :loc, :page, :facet, :availability 

	def initialize args
    	args.each do |k,v|
      		instance_variable_set("@#{k}", v) unless v.nil?
    	end
  	end

  	def availability_check
  		if self.availability == "on"
  			true
  		else
  			false
  		end
  	end

  	def search_path
  		path = '?query=' + self.query unless self.query.nil?
  		path += '&sort=' + self.sort unless self.sort.nil?
  		path += '&qtype=' + self.qtype unless self.qtype.nil?
  		path += '&format=' + self.format unless self.format.nil?
  		path += '&loc=' + self.loc unless self.loc.nil?
  		path += '&availability=' + self.availability unless self.availability.nil?
  		return path
  	end

  	def search_path_with_page_facet
  		path = '?query=' + self.query unless self.query.nil?
  		path += '&sort=' + self.sort unless self.sort.nil?
  		path += '&qtype=' + self.qtype unless self.qtype.nil?
  		path += '&format=' + self.format unless self.format.nil?
  		path += '&loc=' + self.loc unless self.loc.nil?
  		path += '&page=' + self.page unless self.page.nil?
  		path += '&availability=' + self.availability unless self.availability.nil?
  		self.facet.each do |f|
  			path += '&facet[]=' + f
  		end unless self.facet.nil?
  		return path
  	end


  	def results  		
  		if Rails.cache.exist?(self.search_path_with_page_facet)
      		return Rails.cache.read(self.search_path_with_page_facet)
    	else
  			url = 'https://mr.tadl.org/eg/opac/results?'
  			if self.query
  				url += 'query=' + self.query
  			else
  				url += 'query='
  			end
  			url += '&qtype=' + self.qtype unless self.qtype.nil?
  			url += '&limit=24'
  			url += '&sort=' + self.sort unless self.sort.nil?
  			if self.loc
  				url += '&locg=' + self.loc
  			else
  				url += '&locg=22'
  			end
  			if self.format == 'video_games'
  				url += '&fi%3Aformat=mVG&facet=subject%7Cgenre%5Bgame%5D'
  			elsif self.format == 'all'
  				url += '&fi%3Aformat='
  			else
  				url += '&fi%3Aformat=' + self.format unless self.format.nil?
  			end
  			url += '&page=' + self.page unless self.page.nil?
  			if self.availability == "on"
  				url += '&modifier=available'
  			end
  			facets_for_url = ''
  			self.facet.each do |f|
					facets_for_url += '&facet=' + f
			end unless self.facet.nil?
			url += facets_for_url
  			agent = Mechanize.new
  			page = agent.get(url)
  			page = page.parser
  			results = Array.new
  			page.css('.result_table_row').each do |result|
  				item_raw ={:title => result.at_css(".record_title").text.strip,
					:author => result.at_css('[@name="item_author"]').text.strip.try(:squeeze, " "),
					:availability => process_availability(result.css(".result_count").reverse.map {|i| i.try(:text).try(:strip)}),
					:copies_availabile => process_availability(result.css(".result_count").reverse.map {|i| clean_availablity_counts(i.try(:text))[0]}),
					:copies_total => process_availability(result.css(".result_count").reverse.map {|i| clean_availablity_counts(i.try(:text))[1]}),
					:record_id => result.at_css(".record_title").attr('name').sub!(/record_/, ""),
        	    	:eresource => result.at_css('[@name="bib_uri_list"]').try(:css, 'td').try(:css, 'a').try(:attr, 'href').try(:text).try(:strip),
					#hack for dev below
					:image => 'http://catalog.tadl.org' + result.at_css(".result_table_pic").try(:attr, "src"),
					:abstract => result.at_css('[@name="bib_summary"]').try(:text).try(:strip).try(:squeeze, " "),
					:contents => result.at_css('[@name="bib_contents"]').try(:text).try(:strip).try(:squeeze, " "),
					#hack for dev below
					:format_icon => 'http://catalog.tadl.org' + result.at_css(".result_table_title_cell img").try(:attr, "src"),
					:format_type => scrape_format_year(result)[0],
					:record_year => scrape_format_year(result)[1],
					:call_number => result.at_css('[@name="bib_cn_list"]').try(:css, 'td[2]').try(:text).try(:strip)
				}
				item = Result.new item_raw
				results = results.push(item)
  			end
  			facets = Array.new
  			page.css(".facet_box_temp").map do |facet|
  				sub_facets = Array.new
  				facet.css("div.facet_template").each do |sub|
  					sub_raw = { :title => sub.at_css('.facet').text.strip.try(:squeeze, " "),
  								:path => process_facets(sub.css('a').attr('href').text.split('?')[1].split(';')),
  								:selected => check_selected(sub)
  					}
  					sub_facets = sub_facets.push(sub_raw)
  				end
				facet_raw = { :type => facet.at_css('.header/.title').text.strip.try(:squeeze, " "),
							  :subfacets => sub_facets
				}
				facet_new = Facet.new facet_raw
				facets = facets.push(facet_new)
			end
			if page.css('.search_page_nav_link:contains(" Next ")').present?
				more_results = true
			else
				more_results = false
			end
			Rails.cache.write(self.search_path_with_page_facet, [results, facets, more_results] ,:expires_in => 5.minutes)
  			return results, facets, more_results
  		end
  	end	
	
  	def clean_availablity_counts(text)
		availability_array = text.strip.split('of')
		total_availabe = availability_array[0].strip
		total_copies_scope_arrary = availability_array[1].split('at', 2)
		total_copies = total_copies_scope_arrary[0].gsub('copy', '').gsub('copies', '').gsub('available','').strip 
		availability_scope = total_copies_scope_arrary[1]
		return total_availabe, total_copies, availability_scope
	end

	def check_e_resource(item)
		if item.at_css('span.result_place_hold')
			e_resource = false 
		else
			e_resource = true 
		end
		return e_resource
	end

	def scrape_format_year(item)
		format_year = item.css('div#bib_format').try(:text).try(:split, '(')
		format = format_year[0].strip rescue nil
		year = format_year[1].strip.gsub(')', '')	rescue nil
		result = [format, year]
		return result		
	end

	def process_facets(facet)
		facet.delete_if {|f| f !~ /facet=/} 
		clean_facet = ''
		facet.each do |f|
			f.gsub!('facet=','&facet[]=')
			f = URI::encode(f)
			clean_facet += f
		end
		return clean_facet
	end

	def check_selected(facet)
		if facet['class'].include? 'facet_template_selected'
			return true
		else
			return false
		end
	end

	def process_availability(availability)
		availability.pop
		return availability
	end

end
