module ApplicationHelper
    def format_icon(value, option_array)
        option_array.each do |option|
            if value.to_s == option[2].to_s
                return option[1]
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
        location_code = Settings.all_locations_code
        Settings.elastic_locations.each do |l|
            if location == l[0]
                location_code = l[1] 
            end
        end
        return location_code
    end

end
