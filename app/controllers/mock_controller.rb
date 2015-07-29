class MockController < ApplicationController
    include ApplicationHelper
    before_filter :shared_mock_variables, :generate_user
    respond_to :html, :json, :js

  def index
      
    if Rails.cache.exist?('music_list')
      @music_list = Rails.cache.read('music_list')
    else
      music_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/31/json').read)['nodes'].map {|i| i['node']}
      @music_list = Dish(music_list_raw)
      Rails.cache.write('music_list', @music_list, expires_in: 10.minutes)
    end
      
    if Rails.cache.exist?('movie_list')
      @movie_list = Rails.cache.read('movie_list')
    else
      movie_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/32/json').read)['nodes'].map {|i| i['node']}
      @movie_list = Dish(movie_list_raw)
      Rails.cache.write('movie_list', @movie_list, expires_in: 10.minutes)
    end

    if Rails.cache.exist?('book_list')
      @book_list = Rails.cache.read('book_list')
    else
      book_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/68/json').read)['nodes'].map {|i| i['node']}
      @book_list = Dish(book_list_raw)
      Rails.cache.write('book_list', @book_list, expires_in: 10.minutes)
    end

    if Rails.cache.exist?('game_list')
      @games_list = Rails.cache.read('game_list')
    else
      game_list_raw = JSON.parse(open('https://www.tadl.org/mobile/export/items/505/json').read)['nodes'].map {|i| i['node']}
      @games_list = Dish(game_list_raw)
      Rails.cache.write('game_list', @games_list, expires_in: 10.minutes)
    end
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
    @user = generate_user()
    if @user.token
      set_cookies(@user)
    end
    respond_to do |format|
      format.json {render json: @user}
      format.js
    end
  end

  def logout
    cookies.delete :login
    cookies.delete :user
    @message = "logged out"
    respond_to do |format|
      format.json {render json: @message}
      format.js
    end
  end

  def place_hold
    @check_user = generate_user()
    if !@check_user.error
      if params[:record_id] && !params[:record_id].blank?
        if !params[:force]
          @hold_confirmation = @check_user.place_hold(params['record_id'])[0]
        else
          @hold_confirmation = @check_user.force_hold(params['record_id'])[0]
        end
      else
        @hold_confirmation = 'no records submitted for holds'
      end
    else
      @hold_confirmation = 'bad login'
    end
    @user = generate_user()
    set_cookies(@user)
    respond_to do |format|
      format.js
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
        @user = @confirmation[1]
        set_cookies(@user)
        @holds = @confirmation[0]
      else
        @confirmation = 'bad parameters'
      end
    else
      @confirmation = 'bad login'
    end
    respond_to do |format|
      format.js
      format.json {render :json => {:user => @user, 
        :checkouts => @checkouts}}
    end 
  end

  def list_holds
    @user = generate_user()
    if !@user.error
      @holds = @user.list_holds
      set_cookies(@user)
    else
      @holds = 'bad login'
      redirect_to mock_index_path
      return
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
      set_cookies(@user)
    else
      @checkouts = 'bad login'
      redirect_to mock_index_path
      return
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
      set_cookies(@check_user)
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
    @user = generate_user()
    if !@user.error
      set_cookies(@user)
      @fines = @user.fines
    else
      @fines = 'bad login'
      redirect_to mock_index_path
      return
    end
    respond_to do |format|
      format.html
      format.json {render :json => {:user => @user, 
        :fines => @fines}}
    end
  end

  def payments
    @user = generate_user()
    if !@user.error
      set_cookies(@user)
      @payments = @user.payments
    else
      @payments = 'bad login'
      redirect_to mock_index_path
      return
    end
    respond_to do |format|
      format.html
      format.json {render :json => {:user => @user, 
        :payments => @payments}}
    end
  end

  def preferences
    @user = generate_user()
    if !@user.error
      set_cookies(@user)
      @preferences = @user.preferences
    else
      @preferences = 'bad login'
      redirect_to mock_index_path
      return
    end
    respond_to do |format|
      format.js
      format.html
      format.json {render :json => {:user => @user, 
        :preferences => @preferences}}
    end
  end

  def update_notifications
    @user = generate_user()
    if !@user.error
      @preferences = @user.update_notify_preferences(params)
    else
      @preferences = 'bad login'
    end
    respond_to do |format|
      format.html
      format.json {render :json => {:user => @user, 
        :preferences => @preferences}}
    end
  end

  def update_search_history
    @user = generate_user()
    if !@user.error
      @preferences = @user.update_search_history_preferences(params)
      set_cookies(@user)
    else
      @preferences = 'bad login'
    end
    respond_to do |format|
      format.json {render :json => {:user => @user, 
        :preferences => @preferences}}
    end
  end

end
