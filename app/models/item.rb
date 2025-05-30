class Item
	include ActiveModel::Model
	require 'open-uri'
	attr_accessor :title, :author, :availability, :copies_available, :copies_total,
                :id, :eresource, :image, :abstract, :abstract_array, :contents, :contents_array,
                :format_icon, :format_type, :record_year, :call_number, :publisher, :holdable,
                :publication_place, :isbn, :physical_description, :all_copies_available,
                :all_copies_total, :loc_copies_total, :loc_copies_available, :author_other,
                :subjects, :genres, :series, :holdings, :search_layout, :loc, :electronic,
                :score, :holds, :source, :fiction, :abridged

  def initialize args
    args.each do |k,v|
        instance_variable_set("@#{k}", v)
    end
  end

  def clean_holdings
    holdings = Array.new
    self.holdings.each do |h|
      if h[0].is_a? String
        h.shift
      end
      holdings.push(h)
    end rescue []
    return holdings.flatten
  end

  	def check_trailer
  		fetch_trailer = JSON.parse(open('https://tools.app.tadl.org/trailers/get_trailer.json?id=' + self.id.to_s, {:read_timeout => 1}).read) rescue nil
  		if fetch_trailer.nil? || !fetch_trailer['message'] || fetch_trailer['message'] == 'error'
  			trailer = nil
  		else
  			trailer_id = fetch_trailer['message']
  		  trailer = '<div class="embed-responsive embed-responsive-16by9"><iframe src="https://www.youtube.com/embed/' + trailer_id.to_s + '?iv_load_policy=3&amp;modestbranding=1&amp;rel=0"></iframe></div>'
      end
  		return trailer
  	end

  	def goodreads
      if (self.format_type.include? ("a")) || (self.format_type.include? ("t"))
        isbns = self.isbn.split(' ')
        request = String.new
        isbns.each do |i|
          request += i.gsub(/\D/, '') + ','
        end rescue nil
        fetch_review = JSON.parse(open('https://toolbox.tadl.org/goodreads?isbn=' + request, {:read_timeout => 1}).read) rescue nil
        return fetch_review
      end rescue nil
  	end

  	def clean_related(subject)
 		subject.gsub!(/\n/, "")
  		subject.gsub!(/<[^<>]*>/, "")
      subject.gsub!('.','')
  		subject.to_s
  		subject.split('&gt;')
  	end

    def process_related(related)
      clean = Array.new
      related.each do |r|
        subject_hash = Hash.new
        subject_hash['heading'] = r.css('.rdetail_subject_type').try(:text)
        subject_array = Array.new
        r.css('.rdetail_subject_value').to_s.split('<br>').reverse.drop(1).reverse.each do |a|
          subject_array = subject_array.push(clean_related(a))
        end
        subject_hash['items'] = subject_array
        clean = clean.push(subject_hash)
      end
      return clean
    end


  	def clean_totals_holds(text)
  		totals = text.split('with') rescue nil
  		total_holds = totals[0].gsub('current holds','').strip rescue nil
  		total_copies = totals[1].gsub('total copies.','').strip rescue nil
  		return total_holds, total_copies
  	end

    def marc
      url = 'https://' + Settings.machine_readable + '/eg/opac/record/' + self.id + '?expand=marchtml#marchtml'
      agent = Mechanize.new
      page = agent.get(url)
      marc_record = page.parser.at_css('.marc_table').to_s.gsub(/\n/,'').gsub(/\t/,'')
      return marc_record
    end

    def grid_available_panel
        if self.loc_copies_available > 0
            return "panel-success"
        elsif self.electronic == true
            return "panel-success"
        else
            return "panel-default"
        end
    end

    def grid_available_text
        if self.loc_copies_available > 0
            if self.loc == "22" or self.loc == '' or self.loc == '47' or self.loc == '43'
              location_text = 'in ' + Settings.system_synonym
            else
              location_text = "at selected location"
            end
            return "<strong>" + self.loc_copies_available.to_s + " available " + location_text  + "</strong>"
        elsif self.eresource == true
            return "<strong>On Demand E-Resource</strong>"
        else
            return ""
        end
    end

    def create_params
      hash = Hash.new
      self.instance_variables.each {|v| hash[v.to_s.delete("@")] = self.instance_variable_get(v)}
      return hash
    end

    def checkout_limit
      if ENV['SYSTEM_NAME'] == 'tadl'
        self.holdings.each do |h|
          if h['location'] == 'STEM Kits'
            return "2 STEM kits per account"
          elsif h['call_number'].include?("LAUNCHPAD")
            return "2 Launchpads per account"
          end
        end
      end
      return false
    end
    

end
