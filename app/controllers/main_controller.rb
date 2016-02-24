class MainController < ApplicationController
    include ApplicationHelper
    before_filter :shared_main_variables, :generate_user
    respond_to :html, :json, :js

  def index
    @lists = Settings.lists
    @last_updated = Rails.cache.read('last_updated')
    @featured_items = Array.new
    @lists.each do |l|
      list = Hash.new
      list["title"] = l["name"]
      list["items"] = Rails.cache.read(l["name"])
      @featured_items = @featured_items.push(list)
    end

    respond_to do |format|
      format.html
      format.json {render :json => {:last_updated => @last_updated, :featured_items => @featured_items}}
    end
  end


  def search
    @search = Search.new params
    if (@search.query && @search.query != '') || @search.canned == 'true'
      results = @search.results
      @items = results[0]
      @facets = results[1]
      @more_results = results[2]
    else
      @items = Array.new
      @facets = Array.new
      @more_results = nil
      @blank_search = true
    end
    respond_to do |format|
      format.html
      format.js
      format.json {render :json => {:items => @items.first(60), :facets => @facets, :more_results => @more_results}}
    end
  end


  def details
    if params['title']
      @item = Item.new params
    elsif params['id']
      @item_search = Search.new :qtype => 'record_id', :query => params['id']
      @item = @item_search.results[0][0]
    end
    if params['list_name']
      @list_name = params['list_name']
    end 
    if cookies[:login] && cookies[:lists]
      lists = JSON.parse(cookies[:lists])
      @lists = Array.new
      lists.each do |l|
        if l['default_list'] == true
          @default_list = l['list_id']
        end
        @lists = @lists.push(l)
      end
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
    if request.path_parameters[:format] == 'json'
      UserListFetcher.perform_async(@user.token)
    end
    respond_to do |format|
      format.json {render json: @user}
      format.js
    end
  end

  def logout
    @user = generate_user()
    clear_user_list_cache(@user)
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
    @hold_id = params[:hold_id]
    @hold_state = params[:hold_state]
    respond_to do |format|
      format.js
    end
  end

  def update_hold_pickup
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

  def holds
    @user = generate_user()
    if !@user.error
      @holds = @user.list_holds
      set_cookies(@user)
    else
      @holds = 'bad login'
      redirect_to main_index_path
      return
    end
    respond_to do |format|
      format.html
      format.json {render :json => {:user => @user,
        :holds => @holds}}
    end
  end

  def hold_history
    @user = generate_user()
    if params[:page]
      page = params[:page].to_i rescue 0
    else
      page = 0
    end
    if !@user.error
      get_holds = @user.get_hold_history(page)
      @holds = get_holds[0]
      @more_results = get_holds[1]
      set_cookies(@user)
    else
      @holds = 'bad login'
      @more_results = 'bad login'
      redirect_to main_index_path
      return
    end
    respond_to do |format|
      format.html
      format.json {render :json => {:user => @user,
        :holds => @holds, :more_results => @more_results}}
    end
  end

  def checkouts
    @user = generate_user()
    if !@user.error
      @checkouts = @user.list_checkouts
      set_cookies(@user)
    else
      @checkouts = 'bad login'
      redirect_to main_index_path
      return
    end
    respond_to do |format|
      format.html
      format.json {render :json => {:user => @user,
        :checkouts => @checkouts}}
    end
  end

  def checkout_history
    @user = generate_user()
    if params[:page]
      @page = params[:page].to_i rescue 0
    else
      @page = 0
    end
    if !@user.error
      get_checkouts = @user.get_checkout_history(@page)
      @checkouts = get_checkouts[0]
      @more_results = get_checkouts[1]
      set_cookies(@user)
    else
      @checkouts = 'bad login'
      @more_results = 'bad login'
      redirect_to main_index_path
      return
    end
    respond_to do |format|
      format.html
      format.js
      format.json {render :json => {:user => @user,
        :checkouts => @checkouts, :more_results => @more_results}}
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
      redirect_to main_index_path
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
      redirect_to main_index_path
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
      key_name = 'list_' + @user.token
      @lists = Rails.cache.read(key_name)
      if @lists.nil?
       @lists = @user.get_lists
      end
    else
      @lists = 'bad login'
      redirect_to main_index_path
      return
    end
    respond_to do |format|
      format.html {render 'lists'}
      format.json {render :json => {:user => @user,
        :lists => @lists}}
    end
  end

  def fetch_list
    @user = generate_user()
    if params[:page]
      page_number = params[:page]
    else
      page_number = '0'
    end
    if params[:sort_by]
      sort_by = params[:sort_by]
    else
      sort_by = 'container_date.descending'
    end
    list_id = params[:list_id]
    @list = @user.fetch_list(list_id, page_number, sort_by)
    
    respond_to do |format|
      format.html {render 'view_list'}
      format.json {render :json => {:user => @user, :list => @list}}
    end
  end

  def add_item_to_list
    @user = generate_user()
    list_id = params[:list_id]
    record_id = params[:record_id]
    if !@user.error
      set_cookies(@user)
      @message = @user.add_item_to_list(list_id, record_id)
    else
      @message = 'bad login'
      redirect_to main_index_path
      return
    end
    respond_to do |format|
      format.json {render :json => {:message => @message}}
    end
  end
  
  def remove_item_from_list
    @user = generate_user()
    list_id = params[:list_id]
    list_item_id = params[:list_item_id]
    if !@user.error
      set_cookies(@user)
      @message = @user.remove_item_from_list(list_id, list_item_id)
    else
      @message = 'bad login'
      redirect_to main_index_path
      return
    end
    respond_to do |format|
      format.json {render :json => {:message => @message}}
    end 
  end

  def create_list
    @user = generate_user()
    name = params[:name].to_s
    description = params[:description] 
    shared = params[:shared]    
    if !@user.error && name.to_s != ''
      set_cookies(@user)
      @message = @user.create_list(name, description, shared)
    elsif @user.error
      @message = 'bad login'
      redirect_to main_index_path
      return
    else
      @message = 'invalid parameters'
    end
    clear_user_list_cache(user)
    if request.path_parameters[:format] == 'json'
      UserListFetcher.perform_async(@user.token)
    end
    respond_to do |format|
      format.json {render :json => {:message => @message}}
    end
  end

  def destroy_list
    @user = generate_user()
    list_id = params[:list_id].to_s  
    if !@user.error && list_id.to_s != ''
      set_cookies(@user)
      @message = @user.destroy_list(list_id)
    elsif @user.error
      @message = 'bad login'
      redirect_to main_index_path
      return
    else
      @message = 'invalid parameters'
    end
    clear_user_list_cache(@user)
    if request.path_parameters[:format] == 'json'
      UserListFetcher.perform_async(@user.token)
    end
    respond_to do |format|
      format.json {render :json => {:message => @message}}
    end
  end

  def edit_list
    @user = generate_user()
    name = params[:name]
    description = params[:description] 
    list_id = params[:list_id]    
    if !@user.error && name.to_s != '' && list_id.to_s != '' 
      set_cookies(@user)
      @message = @user.edit_list(list_id, name, description)
    elsif @user.error
      @message = 'bad login'
      redirect_to main_index_path
      return
    else
      @message = 'invalid parameters'
    end
    clear_user_list_cache(@user)
    if request.path_parameters[:format] == 'json'
      UserListFetcher.perform_async(@user.token)
    end
    respond_to do |format|
      format.json {render :json => {:message => @message}}
    end
  end


  def add_note_to_list
    @user = generate_user()
    note = params[:note]
    if note.nil?
      note = ''
    end
    list_item_id = params[:list_item_id] 
    list_id = params[:list_id]    
    if !@user.error && list_item_id.to_s != '' && list_id.to_s != '' 
      set_cookies(@user)
      @message = @user.add_note_to_list(list_id, list_item_id, note)
    elsif @user.error
      @message = 'bad login'
      redirect_to main_index_path
      return
    else
      @message = 'invalid parameters'
    end
    respond_to do |format|
      format.json {render :json => {:message => @message}}
    end
  end

  def edit_note
    @user = generate_user()
    note = params[:note]
    if note.nil?
      note = ''
    end
    note_id = params[:note_id] 
    list_id = params[:list_id]    
    if !@user.error && note_id.to_s != '' && list_id.to_s != '' 
      set_cookies(@user)
      @message = @user.edit_note(list_id, note_id, note)
    elsif @user.error
      @message = 'bad login'
      redirect_to main_index_path
      return
    else
      @message = 'invalid parameters'
    end
    respond_to do |format|
      format.json {render :json => {:message => @message}}
    end
  end

  def share_list
    @user = generate_user()
    #share can equal show or hide
    share = params[:share]
    list_id = params[:list_id]    
    if !@user.error && share.to_s != '' && list_id.to_s != '' 
      set_cookies(@user)
      @message = @user.share_list(list_id, share)
    elsif @user.error
      @message = 'bad login'
      redirect_to main_index_path
      return
    else
      @message = 'invalid parameters'
    end
    clear_user_list_cache(@user)
    if request.path_parameters[:format] == 'json'
      UserListFetcher.perform_async(@user.token)
    end
    respond_to do |format|
      format.json {render :json => {:message => @message}}
    end
  end

  def make_default_list
    @user = generate_user()
    #share can equal show or hide
    list_id = params[:list_id]    
    if !@user.error && list_id.to_s != '' 
      set_cookies(@user)
      @message = @user.make_default_list(list_id)
    elsif @user.error
      @message = 'bad login'
      redirect_to main_index_path
      return
    else
      @message = 'invalid parameters'
    end
    clear_user_list_cache(@user)
    if request.path_parameters[:format] == 'json'
      UserListFetcher.perform_async(@user.token)
    end
    respond_to do |format|
      format.json {render :json => {:message => @message}}
    end
  end

  def preferences
    @user = generate_user()
    if !@user.error
      set_cookies(@user)
      @preferences = @user.preferences
    else
      @preferences = 'bad login'
      redirect_to main_index_path
      return
    end
    respond_to do |format|
      format.html
      format.json {render :json => {:user => @user,
        :preferences => @preferences}}
    end
  end

  def edit_preferences
    respond_to do |format|
      format.js
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
