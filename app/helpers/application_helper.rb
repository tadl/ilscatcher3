module ApplicationHelper
    def format_icon(value, option_array)
        option_array.each do |option|
            if value.to_s == option[0].to_s
                return option[1]
            end
        end
    end

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


end
