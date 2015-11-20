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

    def author_search_link(author, search)
        if author && author != ''
            path = request.protocol + request.host_with_port + '/search?query=' + author
            path += '&qtype=author'
            path += '&loc=' + search.loc unless search.loc.nil?
            return path
        else
            return nil
        end 
    end

end
