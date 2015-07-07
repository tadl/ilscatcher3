module ApplicationHelper
    def format_icon(value, option_array)
        option_array.each do |option|
            if value.to_s == option[0].to_s
                return option[1]
            end
        end
    end
end
