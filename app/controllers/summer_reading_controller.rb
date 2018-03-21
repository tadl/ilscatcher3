class SummerReadingController < ApplicationController
    include ApplicationHelper
    before_filter :shared_main_variables
    respond_to :html, :json, :js

    def check_for_participant
    	user = generate_user()
    	if !user.error
    		url = 'http://cal.lib.tadl.org:3000/patron_check_for_participants.json?secret=' + ENV['SUMMER_SECRET'] + '&cards=' + user.cards.to_s
    		response = JSON.parse(open(url).read)
    		message = response["message"]
    	else
    		message = 'user not logged in'
    	end
    	respond_to do |format|
      		format.json {render :json => {:message => message}}
    	end
    end
end