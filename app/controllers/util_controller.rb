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

end
