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
        @logo = 'http://www.tadl.org/sites/all/themes/converge_custom/logo.png'
        @query_options = [['Keyword', 'keyword'], ['Author / Group / Actor', 'author'],['Title', 'title'],['Subject', 'subject'], ['Series', 'series'], ['Genre', 'single_genre']]
        @format_options = Settings.format_options
        @format_options_unlocked = Settings.format_options_unlocked
        @sort_options = [['Relevance', 'relevancy'], ['Newest to Oldest', 'pubdateDESC'],['Oldest to Newest', 'pubdateASC'],['Title A to Z', 'titleAZ'], ['Title Z to A', 'titleZA']]
        @location_options = Settings.location_options
        @pickup_locations = Settings.pickup_locations
        @long_pickup_locations = Settings.long_pickup_locations
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
        @format_names = [['Language material','a'], 
                        ['Notated music','c'], 
                        ['Manuscript notated music','d'], 
                        ['Cartographic material','e'], 
                        ['Manuscript cartographic material','f'], 
                        ['Projected medium','g'], 
                        ['Nonmusical sound recording','i'], 
                        ['Musical sound recording','j'], 
                        ['Two-dimensional nonprojectable graphic','k'], 
                        ['Computer file','m'], 
                        ['Kit','o'], 
                        ['Mixed materials','p'], 
                        ['Three-dimensional artifact or naturally occurring object','r'], 
                        ['Manuscript language material','t'],
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


end
