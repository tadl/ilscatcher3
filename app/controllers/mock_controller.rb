class MockController < ApplicationController
    include ApplicationHelper
    before_filter :shared_mock_variables, :generate_user
    respond_to :html, :json, :js

  def index
    @music_list = Rails.cache.read("music_list")
    @movie_list = Rails.cache.read('movie_list')
    @games_list = Rails.cache.read('game_list')
  end


  def search
    if params["legacy"] == 'true'
      @search = Search_Legacy.new params
    else
      @search = Search.new params
    end
    if @search.query || @search.fmt || @search.shelving_location || @search.list_id
      results = @search.results
      @items = results[0]
      @facets = results[1]
      @more_results = results[2]
    else
      @items = Array.new
      @facets = Array.new
      @more_results = nil
    end
    respond_to do |format|
      format.html
      format.js
      format.json {render :json => {:items => @items.first(60), :facets => @facets, :more_results => @more_results}}
    end
  end


  def details
    @item = Item.new params
    @search = Search.new params
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
    check_user = generate_user()
    @target_holds = params[:hold_id].split(',')
    @task = params[:task]
    if !check_user.error
      if (params[:hold_id] && !params[:hold_id].blank?) || (params[:task] && !params[:task].blank?)
        @confirmation = check_user.manage_hold(@target_holds, @task)
        @user = @confirmation[1]
        set_cookies(@user)
        @holds = @confirmation[0]
      else
        @holds = 'bad parameters'
        @user = check_user
      end
    else
      @user = check_user.error
      @holds = 'bad login'
    end
    respond_to do |format|
      format.js
      format.json {render :json => {:user => @user,
        :holds => @holds, :target_holds => @target_holds}}
    end
  end

  def edit_hold_pickup
    check_user = generate_user()
    @hold = params[:hold_id]
    @new_pickup = params[:new_pickup]
    @hold_state = params[:hold_state]
    if !check_user.error
      @hold = check_user.edit_hold(@hold, @new_pickup, @hold_state)
    else
      @hold = 'bad login'
    end
    respond_to do |format|
      format.js
      format.json {render :json => @hold}
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
        @targeted_records = params[:record_ids].split(',')
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

  def user_lists
    @user = generate_user()
    if !@user.error
      set_cookies(@user)
      @lists = @user.get_lists
    else
      @lists = 'bad login'
      redirect_to mock_index_path
      return
    end
    respond_to do |format|
      format.json {render :json => {:user => @user,
        :lists => @lists}}
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
      format.html
      format.json {render :json => {:user => @user,
        :preferences => @preferences}}
    end
  end

# notification preferences
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

# search preferences and checkout/hold history preferences
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

#user preferences
  def update_user_info
    if params['password']
      @check_user = generate_user()
      if !@check_user.error
        confirmation = @check_user.update_user_info(params)
        @message = confirmation[0]
        @preferences = confirmation[1]
        @user = confirmation[2]
        set_cookies(@user)
      else
        @preferences = 'bad login'
        @message = 'bad login'
        @user = @check_user
      end
      respond_to do |format|
        format.json {render :json => {:message => @message, :user => @user,
          :preferences => @preferences}}
      end
    else
       @message = 'password required'
       respond_to do |format|
        format.json {render :json => {
          :message => @message}}
        end
    end
  end


end
