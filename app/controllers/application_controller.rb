class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    require 'open-uri'
    before_filter :set_headers
    rescue_from Mechanize::Error, with: :scrape_error
    rescue_from SocketError, with: :scrape_error

    def set_headers
        headers['Access-Control-Allow-Origin'] = '*'      
    end  

    def shared_main_variables
        @logo = Settings.logo
        @query_options = [['Keyword', 'keyword'], ['Author / Group / Actor', 'author'],['Title', 'title'],['Subject', 'subject'], ['Series', 'series'], ['Genre', 'single_genre']]
        @format_options = Settings.format_options
        @format_options_unlocked = Settings.format_options_unlocked
        @format_default = Settings.format_options[0][2]
        @sort_options = [['Relevance', 'relevancy'], ['Newest to Oldest', 'pubdateDESC'],['Oldest to Newest', 'pubdateASC'],['Title A to Z', 'titleAZ'], ['Title Z to A', 'titleZA']]
        @location_options = Settings.location_options
        @pickup_locations = Settings.pickup_locations
        @long_pickup_locations = Settings.long_pickup_locations
        @this_site = Settings.opac_toggle_default
        @truefalseicons = [['glyphicon glyphicon-ok text-success', true], ['glyphicon glyphicon-remove text-danger', false]]
    	@format_icons = [['a','glyphicon-book','text'], 
                        ['c','glyphicon-music','notated music'], 
                        ['d','glyphicon-music','notated music'], 
                        ['e','glyphicon-globe','cartographic'], 
                        ['f','glyphicon-globe','cartographic'], 
                        ['g','glyphicon-film','moving image'], 
                        ['i','glyphicon-cd','sound recording-nonmusical'], 
                        ['j','glyphicon-cd','sound recording-musical'], 
                        ['k','glyphicon-picture','still image'], 
                        ['m','glyphicon-file','software, multimedia'], 
                        ['o','glyphicon-briefcase','kit'], 
                        ['p','glyphicon-briefcase','mixed-material'], 
                        ['r','glyphicon-inbox','three dimensional object'],
                        ['t','glyphicon-book','text']
                    ]
    end

    def generate_user()
        if cookies[:login]
            args = Hash.new
            args['token'] = cookies[:login]
            user = User.new args
        else
            user = User.new params
        end
        return user
    end

    def clear_user_list_cache(user)
        key = 'list_' + user.token
        Rails.cache.delete(key)
    end


    def set_cookies(user)
      cookies[:login] = { :value => user.token, :expires => 2.hours.from_now }
      cookies[:user] = {:value => user.to_json, :expires => 2.hours.from_now }
    end

    def scrape_error
        respond_to do |format|
            format.js  {render :js => "alert_message('danger', 'An error occured. Please try again later.', 10000);" }
            format.html {redirect_to internal_server_error_path}
        end
    end

    def fire_password_reset(token, password_1, password_2)
        agent = Mechanize.new
        url = 'https://mr-v2.catalog.tadl.org/eg/opac/password_reset/' + token
        page = agent.post(url, {'uuid' => token, 'pwd1' => password_1, 'pwd2' => password_2})
        check_for_error = page.parser.css('#main-content/p.error').text
        if check_for_error != ''
            confirmation = check_for_error
        else
            confirmation = 'good'
        end
        return confirmation
    end
end