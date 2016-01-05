module ApplicationHelper
    def format_icon(value, option_array)
        option_array.each do |option|
            if value.to_s == option[2].to_s
                return option[1]
            end
        end
    end

    def format_name(value, option_array)
        option_array.each do |option|
            if value.to_s == option[1].to_s
                return option[0]
            end
        end
    end


    def location_map(value, option_array)
        response = nil
        option_array.each do |option|
            if value.to_s == option[1].to_s
                response = option[0]
            end
        end
        return response
    end

    # def reverse_location_map(value, option_array)
    #     option_array.each do |option|
    #         if value.to_s == option[0].to_s
    #             return option[1]
    #         end
    #     end
    # end

    def goodreads_review(review_data)
        if  !review_data || !review_data["gr_id"]
            return nil
        else
            review = '<span class="goodreads-stars"><a href="' + review_data["gr_link"] +'">'
            review += review_data["stars_html"] + ' on GoodReads.com'
            review += '</a></span>'
            return review.html_safe
        end
    end

    def related_search_link(query, item, type)
        if query && query != ''
            path = request.protocol + request.host_with_port + '/search?query=' + URI.encode(query, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
            path += '&qtype=' + type 
            path += '&loc=' + item.loc unless item.loc.nil?
            path += '&layout=' + item.search_layout unless item.search_layout.nil?
            return path
        else
            return nil
        end 
    end

    def location_to_code(location)
        if location == 'TADL-WOOD'
          location_code = '23' 
        elsif location == 'TADL-IPL'
          location_code = '24'
        elsif location == 'TADL-KBL'
          location_code = '25'
        elsif location == 'TADL-PCL'
          location_code = '26'
        elsif location == 'TADL-FLPL'
          location_code = '27'
        elsif location == 'TADL-EBB'
          location_code = '28'
        else
          location_code = '22'
        end
    return location_code
  end

end
