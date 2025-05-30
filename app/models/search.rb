class Search
  require 'open-uri'
  include ActiveModel::Model
  attr_accessor :query, :sort, :qtype, :fmt, :loc, :page, :facet, :availability,
                :layout, :shelving_location, :list_id, :subjects, :series,
                :authors, :genres, :canned, :search_title, :shelf_lock, :genre_lock, 
                :in_progress, :physical, :min_score, :fiction, :audience

    def initialize args
      args.each do |k,v|
        instance_variable_set("@#{k}", v) unless v.nil?
      end
      if Settings.default_search_display
        instance_variable_set("@layout", Settings.default_search_display) unless args["layout"]
      else
        instance_variable_set("@layout", "grid") unless args["layout"]
      end
      if args["search_title"] && args["qtype"] == 'shelf' || args["search_title"] && args["qtype"] == 'genre' 
        if valid_canned_search(args["search_title"])
          instance_variable_set("@canned", 'true')
          instance_variable_set("@search_title", args["search_title"])
        end
      end
      if !args["loc"] && Settings.shelf_lock
        instance_variable_set("@loc", Settings.shelf_lock.location)
      end
      if args["fmt"]
        format = args["fmt"]
        if args["shelf_lock"] != 'on' && Settings.format_options_unlocked
          all_formats = Settings.format_options_unlocked
        else
          all_formats = Settings.format_options
        end 
        all_formats.each do |f|
            if f[2] == format && f[1] != 'fmt'
              instance_format = '@'+f[1]
              instance_variable_set(instance_format, f[2].split(","))
            end
        end
        i = 0
        all_formats.each do |f|
          if f[2] == format
            i += 1
          end 
        end
        if i == 0
          instance_variable_set("@fmt", nil)
        end
      end
    end

    def availability_check
      if self.availability == "on"
        true
      else
        false
      end
    end

    def physical_check
        if self.physical == "on"
            true
        else
            false
        end
    end

    def valid_canned_search(search_title)
      valid_canned_searches = Settings.lists.each{|key,value| value}
      valid_names = Array.new
      valid_canned_searches.each do |n|
        if n['searches']
          names = n['searches'].each{|key,value| value}
          names.each do |t|
            valid_names = valid_names.push(URI.decode(t['name']))
          end
        end
      end
      if valid_names.include?(search_title)
        return true
      else
        return false
      end
      return true
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
        path += '&qtype=' + self.qtype unless self.qtype.nil?
        path += '&loc=' + self.loc unless self.loc.nil?
        path += '&fmt=' + self.fmt unless self.fmt.nil?
        path += '&availability=' + self.availability unless self.availability.nil?
        path += '&sort=' + self.sort unless self.sort.nil?
        self.shelving_location.each do |s|
          path += '&shelving_location[]=' + s
        end unless self.shelving_location.nil?
        path += '&shelf_lock=' + self.shelf_lock unless self.shelf_lock.nil?
        path += '&search_title=' + self.search_title unless self.search_title.nil?
        path += '&genre_lock=' + self.genre_lock unless self.genre_lock.nil?
        path += '&physical=' + self.physical unless self.physical.nil?
        path += '&min_score=' + self.min_score unless  self.min_score.nil?
        path += '&audience=' + self.audience unless self.audience.nil?
      end
      return path
    end

    def search_path_with_facets
      path = self.search_path
      path += '&fiction=' + self.fiction unless  self.fiction.nil?
      self.subjects.each do |f|
        f = URI::encode(f, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        path += '&subjects[]=' + f
      end unless self.subjects.nil?
      self.genres.each do |f|
        f = URI::encode(f, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        path += '&genres[]=' + f
      end unless self.genres.nil?
      self.series.each do |f|
        f = URI::encode(f, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        path += '&series[]=' + f
      end unless self.series.nil?
      self.authors.each do |f|
        f = URI::encode(f, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        path += '&authors[]=' + f
      end unless self.authors.nil?
      return path
    end

    def search_path_with_facets_minus_fiction
      path = self.search_path
      self.subjects.each do |f|
        f = URI::encode(f, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        path += '&subjects[]=' + f
      end unless self.subjects.nil?
      self.genres.each do |f|
        f = URI::encode(f, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        path += '&genres[]=' + f
      end unless self.genres.nil?
      self.series.each do |f|
        f = URI::encode(f, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        path += '&series[]=' + f
      end unless self.series.nil?
      self.authors.each do |f|
        f = URI::encode(f, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        path += '&authors[]=' + f
      end unless self.authors.nil?
      return path
    end


    def search_path_with_new_facet(facet_type, facet)
      facet = URI.encode(facet, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      path = self.search_path_with_facets
      if facet_type == 'subjects'
        path = path + '&subjects[]=' +  facet
      elsif facet_type == 'genres'
        path = path + '&genres[]=' +  facet
      elsif facet_type == 'series'
        path = path + '&series[]=' +  facet
      elsif facet_type == 'authors'
        path = path + '&authors[]=' +  facet
      end
      return path
    end

    def search_path_minus_selected_facet(facet_type, facet)
      path = self.search_path
      self.subjects.each do |f|
        path = path + '&subjects[]=' +  URI::encode(f, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) unless f == facet and facet_type == 'subjects'
      end unless self.subjects.nil?
      self.genres.each do |f|
        path = path + '&genres[]=' +  URI::encode(f, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) unless f == facet and facet_type == 'genres'
      end unless self.genres.nil?
      self.series.each do |f|
        path = path + '&series[]=' +  URI::encode(f, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) unless f == facet and facet_type == 'series'
      end unless self.series.nil?
      self.authors.each do |f|
        path = path + '&authors[]=' +  URI::encode(f, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) unless f == facet and facet_type == 'authors'
      end unless self.authors.nil?
      return path
    end

    def melcat_link
      query = self.query
      link = 'https://elibrary.mel.org/search/a?searchtype=X&searcharg='+ query +'&SORT=D'
      return link
    end

    def search_path_with_layout
      path = search_path_with_facets
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
      next_page['sort'] = self.sort unless self.sort.nil?
      next_page['shelf_lock'] = self.shelf_lock unless self.shelf_lock.nil?
      next_page['canned'] = self.canned unless self.canned.nil?
      next_page['physical'] = self.physical unless self.physical.nil?
      next_page['min_score'] = self.min_score unless self.min_score.nil?
      next_page['fiction'] = self.fiction unless self.fiction.nil?
      next_page['audience'] = self.audience unless self.audience.nil?

      next_page['subjects'] = Array.new
      self.subjects.each do |f|
        next_page['subjects'] = next_page['subjects'].push(f)
      end unless self.subjects.nil?

      next_page['genres'] = Array.new
      self.genres.each do |f|
        next_page['genres'] = next_page['genres'].push(f)
      end unless self.genres.nil?

      next_page['series'] = Array.new
      self.series.each do |f|
        next_page['series'] = next_page['series'].push(f)
      end unless self.series.nil?

      next_page['authors'] = Array.new
      self.authors.each do |f|
        next_page['authors'] = next_page['authors'].push(f)
      end unless self.authors.nil?

      next_page['shelving_location'] = Array.new
      self.shelving_location.each do |f|
        next_page['shelving_location'] = next_page['shelving_location'].push(f)
      end unless self.shelving_location.nil?

      return next_page
    end

    def results
      url = Settings.elastic_evergreen_url
      # url = 'http://cal.lib.tadl.org:4000/main/index.json?query=' 
      url = url + URI.encode(self.query, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]")) unless self.query.nil?
      url = url + '&page=' + self.page unless self.page.nil?
      url = url + '&search_type=' + self.qtype unless self.qtype.nil?
      url = url + '&format_type=' + self.fmt unless self.fmt.nil?
      url = url + '&sort=' + self.sort unless self.sort.nil?

      if self.availability_check
        url = url + '&available=true'
      end
      if self.subjects
        self.subjects.each do |s|
          url = url + '&subjects[]=' + URI.encode(s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        end
      end
      if self.genres
        self.genres.each do |s|
          url = url + '&genres[]=' +  URI.encode(s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        end
      end
      if self.series
        self.series.each do |s|
          url = url + '&series[]=' +  URI.encode(s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        end
      end
      if self.authors
        self.authors.each do |s|
          url = url + '&authors[]=' +  URI.encode(s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        end
      end
      if self.shelving_location
        self.shelving_location.each do |s|
          url = url + '&shelving_location[]=' +  s
        end
      elsif self.shelf_lock == 'on'
        shelf_locks = Settings.shelf_lock.shelves
        shelf_locks.each do |s|
          url = url + '&shelving_location[]=' +  s.to_s
        end
        self.loc = Settings.shelf_lock.location
      end
      url = url + '&location_code=' + self.loc unless self.loc.nil?
      if self.physical_check
        url = url + '&physical=true' 
      end
      if self.sort != 'relevancy' && !self.sort.nil? && self.min_score.nil?
        self.min_score = '1' 
      end
      url = url + '&min_score=' + self.min_score unless self.min_score.nil?
      url = url + '&fiction=' + self.fiction unless self.fiction.nil?
      url = url + '&audience=' + self.audience unless self.audience.nil?
      puts '----------------------'
      puts 'URL: ' + url
      puts '----------------------'
      request = JSON.parse(open(url).read) 
      results = Array.new
      genres_raw = Array.new
      subjects_raw = Array.new
      series_raw = Array.new
      author_raw = Array.new
      request.each do |r|
        sorted_holdings = r['holdings'].sort_by {|h| h['call_number']}
        location = self.loc rescue ''
        holdings = process_holdings(sorted_holdings, location)
        availability_details = process_availability(sorted_holdings, location)
        item_raw = {
          :title => r["title_display"],
          :author => r["author"],
          :author_other => r["author_other"],
          :holdings => sorted_holdings,
          :availability => availability_details,
          :all_copies_available => holdings[1],
          :all_copies_total => holdings[2],
          :loc_copies_available => holdings[3],
          :loc_copies_total => holdings[4],
          :holds => r["hold_count"],
          :id => r["id"],
          :abstract => r["abstract"],
          :abstract_array => r["abstract_array"],
          :contents => r["contents"],
          :contents_array => r["contents_array"],
          :electronic => r["electronic"],
          :eresource => process_eresource(r["links"]),
          :source => r["source"],
          :format_type => r["type_of_resource"],
          :record_year => r["sort_year"],
          :holdable => r["holdable"],
          :call_number => holdings[0],
          :loc => self.loc,
          :publisher => r["publisher"],
          :publication_place => r["publication_location"],
          :physical_description => r["physical_description"],
          :isbn => r["isbn"][0],
          :subjects => r["subjects"],
          :genres => r["genres"],
          :series => r["series"],
          :score => r["score"],
          :fiction => r["fiction"]
        }
        if item_raw[:format_type] == 'sound recording-nonmusical'
          item_raw[:title] = item_raw[:title].to_s + ' (AUDIOBOOK)' 
        end
        i = 0
        if item_raw[:format_type] == 'sound recording-musical' && item_raw[:holdings][0] && item_raw[:holdings][0]['location_id'] == 533
          item_raw[:title] = item_raw[:title].to_s + ' (VINYL)'
        end 
        item = Item.new item_raw
        results = results.push(item)
        r["genres"].each do |g|
          genres_raw = genres_raw.push(g)
        end rescue nil
        r["subjects"].each do |s|
          if !s.nil? && s != ''
            subjects_raw = subjects_raw.push(s)
          end
        end rescue nil
        r["series"].each do |s|
          series_raw = series_raw.push(s)
        end rescue nil
        author_raw = author_raw.push(r["author"])
      end
      subject_facets = process_facets('subjects', subjects_raw)
      genre_facets = process_facets('genres', genres_raw)
      series_facets = process_facets('series', series_raw)
      author_facets = process_facets('authors', author_raw)
      facets = [subject_facets, author_facets, series_facets, genre_facets]
      if results.size > 24
        more_resulsts = true
      else
        more_resulsts = false
      end
      return results.first(24), facets, more_resulsts
    end

  def process_facets(facet_name, facet_group)
    facets = Array.new
    compact_subjects = facet_group.compact.reject { |c| c.empty? }
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
      :type => facet_name.capitalize,
      :type_raw => facet_name,
      :subfacets => filtered_subjects.sort_by {|_key, value| value}.reverse.to_h.keys.first(10).sort_by { |k| k.downcase }
    }
    facet = Facet.new facet_raw
    return facet
  end

  def active_facet(type, facet)
    if self.send(type.to_sym).include?(facet)
      return true
    else
      return false
    end rescue false
  end

  def process_eresource(url)
    good_url = []
    if url.kind_of?(Array)
      url.each do |link|
        if (link.include? 'http://via.tadl.org') || (link.include? 'https://www.hoopladigital.com/') || (link.include? 'https://goo.gl/') || (link.include? 'https://bit.ly') || (link.include? 'https://tinyurl.com') || (link.include? 'https://drive.google.com/')    
          good_url.push(link)
        end
      end
    end
    if good_url != ''
      return good_url
    else
      return nil
    end
  end

  def process_holdings(availability, location)
    location_code = code_to_location(location)
   if availability != nil or availability != ''
      all_available = 0
      all_total = 0
      location_available = 0
      location_total = 0
      availability.each do |a|
        all_total = all_total + 1
        if a["status"] == "Available" || a["status"] == "Reshelving" || a["status"] == "New Serial"
          all_available = all_available + 1
        end
        if location_code != ''
          if (a["status"] == "Available" || a["status"] == "Reshelving" || a["status"] == "New Serial") && a["circ_lib"] == location_code
            location_available = location_available + 1
          end
          if a["circ_lib"] == location_code
            location_total = location_total + 1
          end
        else
          location_total = all_total
          location_available = all_available
        end

      end
      call_number = availability[0]["call_number"] rescue nil
    else
      call_number = nil
      location_available = nil
      location_total = nil
      all_available = nil
      all_total = nil
    end
    return call_number, all_available, all_total, location_available, location_total
  end

  def process_availability(availability, location)
    #only look at available holdings
    holdings = Array.new
    only_available = availability.reject {|k| k['status'] != "Available" && k['status'] != "Reshelving" && k['status'] != "New Serial"}
    #create array of locations with available copies
    locations = Array.new
    only_available.each do |l|
      locations.push(l['circ_lib'])
    end
    # go through each unique location that has available copy
    locations.uniq.each do |l|
      #create hash that contains per location data
      location_holdings = Hash.new
      location_holdings['library'] = l
      location_holdings['code'] = location_to_code(l)
      #create array that contains available copies per each unique location
      copies_per_location = Array.new
      only_available.each do |i|
        if i['circ_lib'] == l
          copies_per_location.push(i)
        end
      end
      #create array of each unique shelving location
      unique_shelves = Array.new
      copies_per_location.each do |c|
        unique_shelves.push(c['location'])
      end
      #go through each unique shelving location get count and call numbers
      process_shelves = Array.new
      unique_shelves.uniq.each do |s|
        location_copies = Hash.new
        call_numbers = Array.new
        copy_count = 0
        copies_per_location.each do |c|
          if c['location'] == s
            copy_count += 1  
            call_numbers.push(c['call_number'])
          end
        end
        location_copies['count'] = copy_count  
        location_copies['shelf_location'] = s
        location_copies['call_numbers'] = call_numbers.uniq
        process_shelves.push(location_copies)
      end
      location_holdings['copies'] = process_shelves
      holdings.push(location_holdings)
    end
    return holdings
  end

  def clean_isbn(isbn)
    clean = isbn.strip
  end

  def code_to_location(location_code)
    location = ''
    Settings.elastic_locations.each do |l|
        if location_code == l[1]
            location = l[0] 
        end
    end
    return location
  end

  def location_to_code(location)
    location_code = Settings.all_locations_code
    Settings.elastic_locations.each do |l|
        if location == l[0]
            location_code = l[1] 
        end
    end
    return location_code
  end



end
