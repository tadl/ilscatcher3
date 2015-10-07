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
      url = 'https://elastic-evergreen.herokuapp.com/main/index.json?query=' + self.query
      url = url + '&page=' + self.page unless self.page.nil?
      request = JSON.parse(open(url).read) rescue nil
  		results = Array.new
      genres_raw = Array.new
      subjects_raw = Array.new
      series_raw = Array.new
      request.each do |r|
        item_raw ={
          :title => r["title"],
          :author => r["author"],
          :availability => process_availability(r["holdings"])[0],
          :copies_available => process_availability(r["holdings"])[1],
          :copies_total =>process_availability(r["holdings"])[2],
          :id => r["id"],
          :eresource => r["link"],
          :abstract => r["abstract"],
          :contents => r["contents"],
          # #hack for dev below
          :format_type => r["type_of_resource"],
          :record_year => r["record_year"],
          :call_number => 'c343',
          :loc => self.loc,
          :publisher => r["publisher"],
          :publication_place => r["publication_location"],
          :physical_description => r["physical_description"],
          :isbn => r["isbn"][0],
        }
        item = Result.new item_raw
        results = results.push(item)
        r["genres"].each do |g|
          genres_raw = genres_raw.push(g)
        end
        r["subjects"].each do |s|
          if !s.nil? && s != ''
            subjects_raw = subjects_raw.push(s)
          end
        end
        r["series"].each do |s|
          series_raw = series_raw.push(s)
        end rescue nil 
      end
      subject_facets = process_facets('subects', subjects_raw)
      genre_facets = process_facets('genres', genres_raw)
      series_facets = process_facets('series', series_raw)
      facets = [subject_facets, series_facets, genre_facets]
      if results.size > 48
        more_resulsts = true
      else
        more_resulsts = false
      end
      return results.first(48), facets, more_resulsts
  	end	
	


	def process_facets(facet_name, facet_group)
    facets = Array.new
    compact_subjects = facet_group.compact
    filtered_subjects = Hash.new
    compact_subjects.each do |s|
      filtered_subjects[s] = 0
      facet_group.each do |sub|
        if sub == s 
          filtered_subjects[s] += 1
        end
      end
    end
    facet_raw = {
      :type => facet_name,
      :subfacets => filtered_subjects.sort_by {|_key, value| value}.reverse.to_h.keys.first(10)
    }
    facet = Facet.new facet_raw
    return facet
	end



	def process_availability(availability)
		availability.pop
		return availability
	end

  def clean_isbn(isbn)
    clean = isbn.strip
  end
 
end
