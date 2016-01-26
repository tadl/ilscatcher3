class UtilController < ApplicationController
    include ApplicationHelper
    layout "youtube"
    respond_to :html

    def youtube
        id = params[:id]
        fetch_trailer = JSON.parse(open('https://trailer-tank.herokuapp.com/main/get_trailer.json?id=' + id, {:read_timeout => 1}).read) rescue nil
        if fetch_trailer.nil? || !fetch_trailer['message'] || fetch_trailer['message'] == 'error'
            trailer = ""
        else
            trailer_id = fetch_trailer['message']
            trailer = '<div class="embed-responsive embed-responsive-16by9"><iframe src="https://www.youtube.com/embed/' + trailer_id.to_s + '?iv_load_policy=3&amp;modestbranding=1&amp;rel=0"></iframe></div>'
        end
        render :template => "util/youtube", :locals => {:trailer => trailer}
    end

end
