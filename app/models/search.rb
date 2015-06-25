class Search
	include ActiveModel::Model
	attr_accessor :query, :sort, :qtype, :format, :loc, :page, :facet, :availability

	def initialize args
    	args.each do |k,v|
      		instance_variable_set("@#{k}", v) unless v.nil?
    	end
  	end


  	def results
  		url = 'https://mr.tadl.org/eg/opac/results?'
  		if self.query
  			url += 'query=' + self.query
  		else
  			url += 'query='
  		end
  		url += '&sort=' + self.sort unless self.sort.nil?
  		url += '&qtype' + self.qtype unless self.qtype.nil?
  		if self.loc
  			url += '&locg=' + self.loc
  		else
  			url += '&locg=22'
  		end
  		if self.format == 'video_games'
  			url += '&fi%3Aformat=mVG&facet=subject%7Cgenre%5Bgame%5D'
  		else
  			url += '&fi%3Aformat=' + self.format unless self.format.nil?
  		end
  		url += '&page=' + self.page unless self.page.nil?
  		if self.availability == 'yes'
  			url += '&modifier=available'
  		end
  		url += '&limit=24'
  		agent = Mechanize.new
  		page = agent.get(url)
  		results = Array.new
  		page.parser.css('.result_table_row').each do |result|
  			item_raw ={:title => result.at_css(".record_title").text.strip,
				:author => result.at_css('[@name="item_author"]').text.strip.try(:squeeze, " "),
				:availability => result.css(".result_count").map {|i| i.try(:text).try(:strip)},
				:copies_availabile => result.css(".result_count").map {|i| clean_availablity_counts(i.try(:text))[0]},
				:copies_total => result.css(".result_count").map {|i| clean_availablity_counts(i.try(:text))[1]},
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
  		page.parser.css(".facet_box_temp").map do |facet|
  			sub_facets = Array.new
  			facet.css("div.facet_template").each do |sub|
  				sub_raw = { :title => sub.at_css('.facet').text.strip.try(:squeeze, " "),
  							:path => sub.css('a').attr('href').text.split('?')[1].split(';').drop(1).each {|i| i.gsub! 'facet=',''}
  				}
  				sub_facets = sub_facets.push(sub_raw)
  			end
			facet_raw = { :type => facet.at_css('.header/.title').text.strip.try(:squeeze, " "),
						  :subfacets => sub_facets
			}
			facet_new = Facet.new facet_raw
			facets = facets.push(facet_new)
		end

  		return results, facets
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

end
