class MockController < ApplicationController
    include ApplicationHelper
    before_filter :shared_mock_variables
    respond_to :html, :json, :js



  def index
      music_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/31/json').read)['nodes'].map {|i| i['node']}
      movie_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/32/json').read)['nodes'].map {|i| i['node']}
      book_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/68/json').read)['nodes'].map {|i| i['node']}
      games_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/505/json').read)['nodes'].map {|i| i['node']}
      @movie_list = Dish(movie_list_raw)
      @music_list = Dish(music_list_raw)
      @book_list = Dish(book_list_raw)
      @games_list = Dish(games_list_raw)
  end


  def search
    @format_options = [['All Formats', 'all'],['Movies', 'g'],['Music', 'j']]
    @search = Search.new params
    results = @search.results
    @items = results[0]
    @facets = results[1]
    @more_results = results[2]
    respond_to do |format|
      format.html
      format.js
      format.json {render json: @items}
    end
  end


  def details
    @item = Item.new params
    @copies_on_shelf = @item.copies_on_shelf
    @copies_all = @item.copies

    if params["fetching"] == 'true'
      @fetching = true
    end
    respond_to do |format|
      format.html
      format.js
      format.json { render json: @item }
    end
  end

  def login
    @update = params["update"]
    @user = User.new params
    respond_to do |format|
      format.json {render json: @user}
      format.js
    end
  end

  def place_hold
    @check_user = User.new params
    if !@check_user.error
      if params[:record_id] || !params[:record_id].blank?
        @hold_confirmation = @check_user.place_hold(params['record_id'])
      else
        @hold_confirmation = 'no records submitted for holds'
      end
    else
      @hold_confirmation = 'bad login'
    end
    @user = User.new params
    respond_to do |format|
      format.json {render :json => {:user => @user, 
        :hold_confirmation => @hold_confirmation}}
    end
  end

  def list_holds
    @user = User.new params
    if !@user.error
      @holds = @user.list_holds
    else
      @holds = 'bad login'
    end
    respond_to do |format|
      format.json {render :json => {:user => @user, 
        :holds => @holds}}
    end
  end


end
