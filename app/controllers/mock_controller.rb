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
    end
    respond_to do |format|
      format.html
      format.json {render :json => {:user => @user, 
        :payments => @payments}}
    end
  end

  def account
    @user = generate_user()
    if !@user.error
        set_cookies(@user)
        @page = params[:page]
        @fines = @user.fines
        @payments = @user.payments
        @checkouts = @user.list_checkouts
        @holds = @user.list_holds
    else
        @account = 'bad login'
    end
    respond_to do |format|
      format.html
    end
  end



end
