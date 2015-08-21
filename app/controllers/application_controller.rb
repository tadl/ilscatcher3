class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    require 'open-uri'
    rescue_from Mechanize::Error, with: :scrape_error
    rescue_from SocketError, with: :scrape_error

    def shared_mock_variables
        @logo = 'http://www.tadl.org/sites/all/themes/converge_custom/logo.png'
        @query_options = [['Keyword', 'keyword'], ['Author', 'author'],['Title', 'title'],['Subject', 'subject']]
    	@format_options = [['All Formats', 'all'], ['Books', 'a'],['Movies', 'g'],['Music', 'j']]
    	@sort_options = [['Relevance', 'relevance'], ['Newest to Oldest', 'pubdate.descending'],['Oldest to Newest', 'pubdate'],['A to Z', 'titlesort'], ['Z to A', 'titlesort.descending']]
    	@location_options = [['All Locations', '22'], ['Woodmere', '23'],['Interlochen', '24'],['Kingsley', '25'], ['Peninsula', '26'], ['East Bay', '28'], ['Fife Lake', '27']]
        @pickup_locations = [['Woodmere (Main) Branch', '23'],
                            ['Interlochen Public Library', '24'],
                            ['Kingsley Branch Library', '25'],
                            ['Peninsula Community Library', '26'],
                            ['Fife Lake Public Library', '27'],
                            ['East Bay Branch Library', '28']]
        @truefalseicons = [['glyphicon glyphicon-ok text-success', true], ['glyphicon glyphicon-remove text-danger', false]]
    	@format_icons = [['a','glyphicon-book'], 
                        ['c','glyphicon-music'], 
                        ['d','glyphicon-music'], 
                        ['e','glyphicon-globe'], 
                        ['f','glyphicon-globe'], 
                        ['g','glyphicon-film'], 
                        ['i','glyphicon-cd'], 
                        ['j','glyphicon-cd'], 
                        ['k','glyphicon-picture'], 
                        ['m','glyphicon-file'], 
                        ['o','glyphicon-briefcase'], 
                        ['p','glyphicon-briefcase'], 
                        ['r','glyphicon-inbox'], 
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
            format.html {redirect_to "http://huwshimi.com/404/"}
        end
    end


end
