class UtilController < ApplicationController
    include ApplicationHelper
    layout "youtube"
    respond_to :html

    TRAILER_TEMPLATE = '<div class="embed-responsive embed-responsive-16by9"><iframe src="https://www.youtube.com/embed/%s?iv_load_policy=3&amp;modestbranding=1&amp;rel=0"></iframe></div>'.freeze

    def youtube
        id = params[:id]
        trailer = TRAILER_TEMPLATE % id
        render :template => "util/youtube", :locals => {:trailer => trailer}
    end

    def rewrite_legacy_account
        url = "/main/preferences"
        redirect_to url 
    end

    def rewrite_legacy_search
    	url = "/main/search?query="
    	url += params[:query] unless params[:query].nil?
    	url += '&qtype=' + params[:qtype] unless params[:qtype].nil?
    	url += '&loc=' + params[:locg] unless params[:locg].nil?
    	if params[:modifier] == 'available'
    		url += '&availability=on'
    	end
    	if params[:sort]
    		url += '&sort=' + process_legacy_sort_options(params[:sort])
    	end
    	redirect_to url
    end

    def process_legacy_sort_options(sort_option)
    	if sort_option == 'titlesort'
    		sort = 'titleAZ'
    	elsif sort_option == 'titlesort.descending'
    		sort = 'titleZA'
    	elsif sort_option == 'authorsort'
    		sort = 'AuthorAZ'
    	elsif sort_option == 'authorsort.descending'
    		sort = 'AuthorZA'
    	elsif sort_option == 'pubdate.descending'
    		sort = 'pubdateDESC'
    	elsif sort_option == 'pubdate'
    		sort = 'pubdateASC'
    	else
    		sort = 'relevancy'
    	end
    	return sort
    end
end
