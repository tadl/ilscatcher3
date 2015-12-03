class Item
	include ActiveModel::Model
	require 'open-uri'
	attr_accessor :title, :author, :availability, :copies_available, :copies_total,
                :id, :eresource, :image, :abstract, :contents, :format_icon,
                :format_type, :record_year, :call_number, :publisher,
                :publication_place, :isbn, :physical_description,
                :all_copies_available, :all_copies_total, :loc_copies_total,
                :loc_copies_available, :author_other, :subjects, :genres, :series, :holdings,
                :search_layout, :loc

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
    end
    return holdings.flatten 
  end

  	def check_trailer
  		fetch_trailer = JSON.parse(open('https://trailer-tank.herokuapp.com/main/get_trailer.json?id=' + self.id.to_s, {:read_timeout => 1}).read) rescue nil
  		if fetch_trailer.nil? || !fetch_trailer['message'] || fetch_trailer['message'] == 'error'
  			trailer = nil
  		else
  			trailer = fetch_trailer['message']
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
        fetch_review = JSON.parse(open('https://reviewcatcher.herokuapp.com/?isbn=' + request, {:read_timeout => 1}).read) rescue nil
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
      url = 'https://mr-v2.catalog.tadl.org/eg/opac/record/' + self.id + '?expand=marchtml#marchtml'
      agent = Mechanize.new
      page = agent.get(url)
      marc_record = page.parser.at_css('.marc_table').to_s.gsub(/\n/,'').gsub(/\t/,'')
      return marc_record
    end

    def grid_available_pannel
        if self.loc_copies_available > 0
            return "panel-success"
        elsif self.eresource != nil
            return "panel-sucess"
        else
            return "panel-default"
        end
    end

    def grid_available_text
        if self.loc_copies_available > 0
            if self.loc == "22" or self.loc == ''
              location_text = 'in district'
            else
              location_text = "at your location"
            end
            return "<span class='text-success'><strong>" + self.loc_copies_available.to_s + " Available " + location_text  + "</strong></span>"
        elsif self.eresource != nil
            return "<span class='text-success'><strong>On Demand E-Resource</strong></span>"
        else
            return ""
        end
    end

    def create_params
      hash = Hash.new
      self.instance_variables.each {|v| hash[v.to_s.delete("@")] = self.instance_variable_get(v)}
      return hash
    end

end
