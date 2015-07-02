class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    require 'open-uri'

    def shared_mock_variables
        @user_name = 'William Rockwood'
        @query_options = [['Keyword', 'keyword'], ['Author', 'author'],['Title', 'title'],['Subject', 'subject']]
    	@format_options = [['All Formats', 'all'], ['Books', 'a'],['Movies', 'g'],['Music', 'j']]
    	@sort_options = [['Relevance', 'relevance'], ['Newest to Oldest', 'pubdate.descending'],['Oldest to Newest', 'pubdate'],['A to Z', 'titlesort'], ['Z to A', 'titlesort.descending']]
    	@location_options = [['All Locations', '22'], ['Woodmere', '23'],['Interlochen', '24'],['Kingsley', '25'], ['Peninsula', '26'], ['East Bay', '28'], ['Fife Lake', '27']]
    	@format_icons = [['Projected medium','glyphicon-film'], ['Computer file','glyphicon-file'], ['Nonmusical sound recording','glyphicon-cd'], ['Musical sound recording','glyphicon-cd'], ['Language material','glyphicon-book']]
    end
end
