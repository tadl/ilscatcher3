class MockController < ApplicationController
    include ApplicationHelper
    before_filter :shared_mock_variables, :generate_user
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
    @user = generate_user()
    if @user.token
      cookies[:login] = { :value => @user.token, :expires => 1.hour.from_now }
    end
    respond_to do |format|
      format.json {render json: @user}
      format.js
    end
  end

  def logout
    cookies.delete :login
    @message = "logged out"
    respond_to do |format|
      format.json {render json: @message}
    end
  end

  def place_hold
    @check_user = generate_user()
    if !@check_user.error
      if params[:record_id] && !params[:record_id].blank?
        @hold_confirmation = @check_user.place_hold(params['record_id'])
      else
        @hold_confirmation = 'no records submitted for holds'
      end
    else
      @hold_confirmation = 'bad login'
    end
    @user = generate_user()
    respond_to do |format|
      format.json {render :json => {:user => @user, 
        :hold_confirmation => @hold_confirmation}}
    end
  end

  def manage_hold
    @check_user = generate_user()
    @hold_id = params[:hold_id]
    @task = params[:task]
    if !@check_user.error
      if (params[:hold_id] && !params[:hold_id].blank?) || (params[:task] && !params[:task].blank?)
        @hold = Hold.new params
        @confirmation = @check_user.manage_hold(@hold)
        @updated_details = @confirmation[1]
        @holds = @confirmation[0]
      else
        @confirmation = 'bad parameters'
      end
    else
      @confirmation = 'bad login'
    end
    respond_to do |format|
      format.js
    end 
  end

  def list_holds
    @user = generate_user()
    if !@user.error
      @holds = @user.list_holds
    else
      @holds = 'bad login'
    end
    respond_to do |format|
      format.html
      format.json {render :json => {:user => @user, 
        :holds => @holds}}
    end
  end

  def list_checkouts
    @user = generate_user()
    if !@user.error
      @checkouts = @user.list_checkouts
    else
      @checkouts = 'bad login'
    end
    respond_to do |format|
      format.html
      format.json {render :json => {:user => @user, 
        :checkouts => @checkouts}}
    end
  end

  def renew_checkouts
    @check_user = generate_user()
    if !@check_user.error
      if (params[:checkout_ids])
        checkouts_raw = params[:checkout_ids].split(',')
        checkouts = Array.new
        if checkouts_raw.is_a?(String)
          checkouts = checkouts.push(checkouts_raw)
        else
          checkouts_raw.each do |c|
            checkouts = checkouts.push(c)
          end
        end
        @targeted_records = params[:record_ids]
        @confirmation = @check_user.renew_checkouts(checkouts)
        @message = @confirmation[0]
        @errors = @confirmation[1]
        @checkouts = @confirmation[2]
      else
        @confirmation = 'bad parameters'
      end
    else
      @confirmation = 'bad login'
    end
    respond_to do |format|
      format.js
      format.json {render :json => {:user => @check_user, 
        :message => @message,
        :errors => @errors,
        :targeted_records => @targeted_records,
        :checkouts => @checkouts}}
    end 
  end

  def marc
    @item = Item.new params
    @marc = @item.marc
    respond_to do |format|
      format.js 
    end 
  end

  def fines
    @check_user = generate_user()
    if !@check_user.error
      @fines = @check_user.fines
    else
      @fines = 'bad login'
    end
    respond_to do |format|
      format.json {render :json => {:user => @check_user, 
        :fines => @fines}}
    end
  end

end
