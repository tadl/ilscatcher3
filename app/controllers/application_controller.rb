class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    require 'open-uri'

    def shared_mock_variables
        @logo = 'http://www.tadl.org/sites/all/themes/converge_custom/logo.png'
        @query_options = [['Keyword', 'keyword'], ['Author', 'author'],['Title', 'title'],['Subject', 'subject']]
    	@format_options = [['All Formats', 'all'], ['Books', 'a'],['Movies', 'g'],['Music', 'j']]
    	@sort_options = [['Relevance', 'relevance'], ['Newest to Oldest', 'pubdate.descending'],['Oldest to Newest', 'pubdate'],['A to Z', 'titlesort'], ['Z to A', 'titlesort.descending']]
    	@location_options = [['All Locations', '22'], ['Woodmere', '23'],['Interlochen', '24'],['Kingsley', '25'], ['Peninsula', '26'], ['East Bay', '28'], ['Fife Lake', '27']]
    	@format_icons = [['Language material','glyphicon-book'], ['Notated music','glyphicon-music'], ['Manuscript notated music','glyphicon-music'], ['Cartographic material','glyphicon-globe'], ['Manuscript cartographic material','glyphicon-globe'], ['Projected medium','glyphicon-film'], ['Nonmusical sound recording','glyphicon-cd'], ['Musical sound recording','glyphicon-cd'], ['Two-dimensional nonprojectable graphic','glyphicon-picture'], ['Computer file','glyphicon-file'], ['Kit','glyphicon-briefcase'], ['Mixed materials','glyphicon-briefcase'], ['Three-dimensional artifact or naturally occurring object','glyphicon-inbox'], ['Manuscript language material','glyphicon-book']]
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
end
