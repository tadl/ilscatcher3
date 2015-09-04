class Search
	require 'open-uri'
	include ActiveModel::Model
	attr_accessor :query, :sort, :qtype, :fmt, :loc, :page, :facet, :availability, :layout, :shelving_location, :list_id
  

	  def initialize args
      args.each do |k,v|
        instance_variable_set("@#{k}", v) unless v.nil?
      end
        instance_variable_set("@layout", "grid") unless args["layout"]
    end

  	def availability_check
  		if self.availability == "on"
  			true
  		else
  			false
  		end
  	end

    def grid_active
      if self.layout == 'grid' 
        active_check = 'active'
      else
        active_check = nil
      end
      return active_check
    end

    def list_active
      if self.layout == 'list'
        active_check = 'active'
      else
        active_check = nil
      end
      return active_check
    end


  	def search_path
      path = ''
      if self
        if !self.query.nil?
  		    path = '?query=' + self.query 
        else
          path = '?query='
        end
  		  path += '&sort=' + self.sort unless self.sort.nil?
  		  path += '&qtype=' + self.qtype unless self.qtype.nil?
  		  path += '&fmt=' + self.fmt unless self.fmt.nil?
  		  path += '&loc=' + self.loc unless self.loc.nil?
  		  path += '&availability=' + self.availability unless self.availability.nil?
        path += '&shelving_location=' + self.shelving_location unless self.shelving_location.nil?
        path += '&list_id=' + self.list_id unless self.list_id.nil?
        path += '&layout=' + self.layout unless self.layout.nil?
  		end
      return path
  	end

    def melcat_link
      query = self.query
      link = 'http://elibrary.mel.org/search/a?searchtype=X&searcharg='+ query +'&SORT=D'
      return link
    end

    def search_path_minus_layout
      path = self.search_path
      path = path.split('&layout')[0] unless self.layout.nil?
      self.facet.each do |f|
        f = URI::encode(f)
        path += '&facet[]=' + f
      end unless self.facet.nil?
      return path
    end

    def search_path_minus_layout_with_page
      path = 'search_'
      path += self.search_path_minus_layout
      path += '&page=' + self.page unless self.page.nil?
      return path
    end

    def search_path_with_facet
      path = self.search_path
      self.facet.each do |f|
        f = URI::encode(f)
        path += '&facet[]=' + f
      end unless self.facet.nil?
      return path
    end

  	def search_path_with_page_facet
  	  path = self.search_path
  		path += '&page=' + self.page unless self.page.nil?
  		self.facet.each do |f|
        f = URI::encode(f)
  			path += '&facet[]=' + f
  		end unless self.facet.nil?
      path = URI::encode(path)
  		return path
  	end

    def next_page_params
      if self.page.nil?
        page = '1'
      else
        page = (self.page.to_i + 1).to_s
      end
      next_page = Hash.new
      next_page['query'] = self.query unless self.query.nil?
      next_page['sort'] = self.sort unless self.sort.nil?
      next_page['qtype'] = self.qtype unless self.qtype.nil?
      next_page['fmt'] = self.fmt unless self.fmt.nil?
      next_page['page'] = page
      next_page['loc'] = self.loc unless self.loc.nil?
      next_page['availability'] = self.availability unless self.availability.nil?
      next_page['layout'] = self.layout unless self.layout.nil?
      next_page['shelving_location'] = self.shelving_location unless self.shelving_location.nil?
      next_page['list_id'] = self.list_id unless self.list_id.nil?
      next_page['facet'] = Array.new
      self.facet.each do |f|
        f = URI::encode(f)
        next_page['facet'] = next_page['facet'].push(f)
      end unless self.facet.nil?
      return next_page
    end


  	def results
      # testing = true
      # if testing == false  		
  		if Rails.cache.exist?(self.search_path_minus_layout_with_page)
      	return Rails.cache.read(self.search_path_minus_layout_with_page)
    	else
  			url = 'https://mr-v2.catalog.tadl.org/eg/opac/results?'
  			if self.query
  				url += 'query=' + self.query
  			else
  				url += 'query='
  			end
        if self.list_id
          url += '&bookbag=' + self.list_id
        end
        if self.qtype.nil?
  			 url += '&qtype=keyword'
        else
          url += '&qtype=' + self.qtype unless self.qtype.nil?
  			end
  			if self.fmt == 'video_games'
  				url += '&fi%3Aformat=mVG&facet=subject%7Cgenre%5Bgame%5D'
  			elsif self.fmt == 'all'
  				url += '&fi%3Aformat='
  			else
  				url += '&fi%3Aformat=' + self.fmt unless self.fmt.nil?
  			end
        url += '&fi%3Alocations=' + self.shelving_location unless self.shelving_location.nil?
        if self.loc
          url += '&locg=' + self.loc
        else
          url += '&locg=22'
        end
  			url += '&sort=' + self.sort unless self.sort.nil?
        url += '&page=' + self.page unless self.page.nil?
  			if self.availability == "on"
  				url += '&modifier=available'
  			end
  			facets_for_url = ''
  			self.facet.each do |f|
					facets_for_url += '&facet=' + f
			end unless self.facet.nil?
			url += facets_for_url
      url += '&limit=24'
  			agent = Mechanize.new
  			page = agent.get(url)
  			page = page.parser
  			results = Array.new
  			page.css('.result_table_row').each do |result|
  				item_raw ={:title => result.at_css(".search_link").text.strip,
					:author => result.at_css('.record_author').text.strip.try(:squeeze, " "),
					:availability => process_availability(result.css(".result_count").reverse.map {|i| i.try(:text).try(:strip)}),
					:copies_available => process_availability(result.css(".result_count").reverse.map {|i| clean_availablity_counts(i.try(:text))[0]}),
					:copies_total => process_availability(result.css(".result_count").reverse.map {|i| clean_availablity_counts(i.try(:text))[1]}),
					:id => result.at_css(".record_title").attr('name').sub!(/record_/, ""),
        	:eresource => result.at_css('[@name="bib_uri_list"]').try(:css, 'td').try(:css, 'a').try(:attr, 'href').try(:text).try(:strip),
					# #hack for dev below
					:image => 'https://catalog.tadl.org' + result.at_css(".result_table_pic").try(:attr, "src"),
					:abstract => result.at_css('tr[@name="bib_summary_full"]').try(:text).try(:strip).try(:squeeze, " "),
					:contents => result.at_css('[@name="bib_contents_full"]').try(:text).try(:strip).try(:squeeze, " "),
					# #hack for dev below
					:format_type => result.css('.marc_record_type').try(:text),
					:record_year => result.at_css('[@name="bib_pubdate"]').try(:text).try(:strip),
					:call_number => result.at_css('[@name="bib_cn_list"]').try(:css, 'td[2]').try(:text).try(:strip),
          :loc => self.loc,
          :publisher => result.at_css('[@name="bib_publisher"]').try(:text).try(:strip),
          :publication_place => result.at_css('[@name="bib_pubplace"]').try(:text).try(:strip),
          :physical_description => result.at_css('[@name="bib_phys_desc"]').try(:text).try(:strip),
          :isbn => result.at_css('[@name="bib_isbn"]').try(:text).try(:strip).try(:squeeze, " "),
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
			Rails.cache.write(self.search_path_minus_layout_with_page, [results, facets, more_results] ,:expires_in => 5.minutes)
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

  def clean_isbn(isbn)
    clean = isbn.strip
  end
 
end
