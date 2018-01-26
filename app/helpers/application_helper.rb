module ApplicationHelper
    def format_icon(item, option_array)
        if item.format_type == 'text' && item.electronic.to_s == 'true' 
            return "glyphicon-phone"
        elsif item.format_type == 'sound recording-nonmusical' && item.electronic.to_s == 'true'
            return "glyphicon-headphones"
        else
            option_array.each do |option|
                if item.format_type.to_s == option[2].to_s
                    return option[1]
                end
            end
        end
    end

    def format_icon_2(value, option_array)
        option_array.each do |option|
            if value.to_s == option[0].to_s
                return option[1]
            end
        end
    end

    def format_name(value, option_array)
        option_array.each do |option|
            if value.to_s == option[0].to_s
                return option[2]
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
            path = '/search?query=' + URI.encode(query, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
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

    def search_link_helper
        search_link = main_search_path
        if Settings.shelf_lock
            search_link << '?shelf_lock=on' 
        end
        return search_link
    end

    def generate_qr(url)
        qr =RQRCode::QRCode.new(url)
        svg = qr.as_svg(offset: 0, color: '000', shape_rendering: 'crispEdges', module_size: 8)
        return svg
    end
end
