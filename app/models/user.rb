class User
	include ActiveModel::Model
	require 'open-uri'
	attr_accessor :full_name, :checkouts, :holds, :holds_ready, :fine, :token, :card, :error, :default_search, :pickup_library, :username

	def initialize args
    if args['full_name']
      args.each do |k,v|
        instance_variable_set("@#{k}", v) unless v.nil?
      end
    else  
		  if args['token'] 
			  agent = create_agent_token(args['token'])
			  basic_info = basic_info(agent)
		  elsif args['username'] && args['password'] 
			  agent_page = create_agent_username_password(args['username'], args['password'])
			  basic_info = basic_info(agent_page[0], agent_page[1])
		  else
			  instance_variable_set("@error", "did not pass token or username & password") 
		  end
    end
	end

	def create_agent_token(token)
		agent = Mechanize.new
		cookie = Mechanize::Cookie.new('ses', token)
		cookie.domain = 'mr-v2.catalog.tadl.org'
		cookie.path = '/'
		agent.cookie_jar.add!(cookie)
		return agent
	end

	def create_agent_username_password(username, password)
		agent = Mechanize.new
		agent.get('https://mr-v2.catalog.tadl.org/eg/opac/myopac/prefs_notify')
		login_form = agent.page.forms[1]
		login_form.field_with(:name => "username").value = username
    login_form.field_with(:name => "password").value = password
    login_form.checkbox_with(:name => "persist").check
    agent.submit(login_form)
    page = agent.page
    return agent, page
	end


	def basic_info(agent, page = nil)
		token = agent.cookies.detect {|c| c.name == 'ses'}
		if !token.nil?
			if page.nil?
				page = agent.get('https://mr-v2.catalog.tadl.org/eg/opac/myopac/prefs_notify')
			end
			basic_info = Hash.new
			page.parser.css('body').each do |p|
				basic_info['full_name'] = p.css('span#dash_user').try(:text).strip rescue nil
				basic_info['checkouts'] =  p.css('#dash_checked').try(:text).strip rescue nil
				basic_info['holds'] =  p.css('span#dash_holds').try(:text).strip rescue nil
				basic_info['holds_ready'] = p.css('span#dash_pickup').try(:text).strip rescue nil
				basic_info['fine'] = p.css('span#dash_fines').try(:text).strip.gsub(/\$/, '') rescue nil
				basic_info['card'] = p.at('td:contains("Active Barcode")').try(:next_element).try(:text) rescue nil
			  basic_info['default_search'] = p.css('select[@name="opac.default_search_location"] option[@selected="selected"]').attr('value').text rescue nil
        basic_info['pickup_library'] = p.css('select[@name="opac.default_pickup_location"] option[@selected="selected"]').attr('value').text rescue nil
        basic_info["username"] = p.at('td:contains("Username")').next.next.text rescue nil
      end
			basic_info.delete_if { |key, value| value.blank? }
			if !basic_info['full_name'].nil?
				basic_info['token'] = token.try(:value)
				basic_info.each do |k,v|
        	instance_variable_set("@#{k}", v) unless v.nil?
      	end
      else
      	instance_variable_set("@error", "bad token") 
      end
		else
			instance_variable_set("@error", "bad username or password") 
		end	
	end

	def place_hold(record_id)
		record_ids = record_id.split(',').reject(&:empty?).map(&:strip).map {|k| "&hold_target=#{k}" }.join
		agent = create_agent_token(self.token)
		agent.get('https://mr-v2.catalog.tadl.org/eg/opac/place_hold?hold_type=T' + record_ids)
		hold_form = agent.page.forms[1]
		agent.submit(hold_form)
    page = agent.page
		confirmation_messages = process_hold_confirmations(page)
    return confirmation_messages, agent
	end

  def force_hold(record_id)
    agent = self.place_hold(record_id)[1]
    hold_form = agent.page.forms[1]
    agent.submit(hold_form)
    page = agent.page
    confirmation_messages = process_hold_confirmations(page)
    return confirmation_messages, agent
  end

  def process_hold_confirmations(page)
    confirmation_messages = page.parser.css('//table#hold-items-list//tr').map do |m|
      {
        :record_id => m.at_css("td[1]//input").try(:attr, "value"),
        :message => m.at_css("td[2]").try(:text).try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip),
      }
    end
    confirmation_messages.each do |c|
      if !c[:message]["Hold was successfully placed"]
        c[:error] = true
        if c[:message]["Placing this hold could result in longer wait times."] 
          c[:need_to_force] = true
        end
      end
    end
    return confirmation_messages
  end

	def list_holds
		agent = create_agent_token(self.token)
		page = agent.get('https://mr-v2.catalog.tadl.org/eg/opac/myopac/holds?limit=41')
		holds_raw = page.parser.css('tr.acct_holds_temp').map do |h|
			{
        	:title =>  h.css('td[2]').css('a').text,
        	:author => h.css('td[3]').css('a').text,
        	:record_id => clean_record(h.css('td[2]').css('a').try(:attr, 'href').to_s),
        	:hold_id => h.search('input[@name="hold_id"]').try(:attr, "value").to_s,
        	:hold_status => h.css('td[8]').text.strip,
        	:queue_status => h.css('/td[9]/div/div[1]').text.strip.gsub(/AvailableExpires/, 'Available, Expires'),
        	:queue_state => h.css('/td[9]/div/div[2]').text.scan(/\d+/).map { |n| n.to_i },
        	:pickup_location => h.css('td[5]').text.strip,
          :format => h.css('.marc_record_type').try(:text),
      		}
      	end
      	sorted_by_hold_id = holds_raw.sort_by {|k| k[:hold_id]}.reverse!
    	sorted_by_hold_id.each do |h|
      		if h[:queue_status] =~ /Available/
        		sorted_by_hold_id.delete(h)
        		sorted_by_hold_id.unshift(h) 
      		end
    	end
    	holds = Array.new
    	sorted_by_hold_id.each do |h|
    		hold = Hold.new h
    		holds = holds.push(hold)
    	end
    	return holds
	end

	def manage_hold(holds, action)
    post_params = Array.new
    if holds.is_a?(String)
      post_params = post_params.push(["hold_id", holds])
    else
      holds.each do |h|
        post_params = post_params.push(["hold_id", h])
      end
    end
    post_params = post_params.push(["action", action]) 
		agent = create_agent_token(self.token)
		agent.post('https://mr-v2.catalog.tadl.org/eg/opac/myopac/holds?limit=41', post_params)
		holds = self.list_holds
		updated_details = self.basic_info(agent)
    user = User.new updated_details
		return holds, user
	end

  def edit_hold(hold, new_value, hold_state)
    agent = create_agent_token(self.token)
    post_params = Array.new
    post_params = post_params.push(["hold_id", hold])
    post_params = post_params.push(["action", "edit"])
    post_params = post_params.push(["pickup_lib", new_value])
    post_params = post_params.push(["expire_time", ""])
    post_params = post_params.push(["frozen", hold_state])
    post_params = post_params.push(["thaw_date", ""])
    url = 'https://mr-v2.catalog.tadl.org/eg/opac/myopac/holds/edit?id=' + hold
    agent.post(url, post_params)
    holds = self.list_holds
    updated_hold = ""
    holds.each do |h|
      if h.hold_id == hold
        updated_hold = h
      end
    end
    return updated_hold
  end

	def list_checkouts
		agent = create_agent_token(self.token)
		page = agent.get('https://mr-v2.catalog.tadl.org/eg/opac/myopac/circs')
		checkouts = scrape_checkouts(page)
    	return checkouts
	end

	def renew_checkouts(checkouts)
		url = 'https://mr-v2.catalog.tadl.org/eg/opac/myopac/circs?action=renew'
		checkouts.each do |c|
			url += '&circ=' + c
		end
		agent = create_agent_token(self.token)
		page = agent.get(url)
		message = page.parser.at_css('div.renew-summary').try(:text).try(:strip)
		errors = page.parser.css('table#acct_checked_main_header').css('tr').drop(1).reject{|r| r.search('span[@class="failure-text"]').present? == false}.map do |checkout| 
  		{
  			:message => checkout.css('span.failure-text').text.strip.try(:gsub, /^Copy /, ''),
  			:checkout_id => checkout.previous.previous.search('input[@name="circ"]').try(:attr, "value").to_s,
        :title => circ_to_title(page, checkout.previous.previous.search('input[@name="circ"]').try(:attr, "value").to_s).try(:gsub, /:.*/, '').try(:strip),
  		}
  	end
  	checkouts = scrape_checkouts(page)
  	return message, errors, checkouts
  end

  def preferences
    url = 'https://mr-v2.catalog.tadl.org/eg/opac/myopac/prefs_notify'
    agent = create_agent_token(self.token)
    agent.get(url)
    page = agent.page.parser
    prefs = Hash.new
    prefs["username"] = page.at('td:contains("Username")').next.next.text rescue nil
    prefs["hold_shelf_alias"] = page.at('td:contains("Holdshelf Alias")').next.next.text rescue nil
    prefs["day_phone"] = page.at('td:contains("Day Phone")').next.next.text rescue nil
    prefs["evening_phone"] = page.at('td:contains("Evening Phone")').next.next.text rescue nil 
    prefs["other_phone"] = page.at('td:contains("Other Phone")').next.next.text rescue nil
    prefs["email"] = page.at('td:contains("Email Address")').next.next.text rescue nil
    prefs["melcat_id"] = page.at('td:contains("MeLCat ID")').next.next.text rescue nil
    prefs["pickup_library"] = page.css('select[@name="opac.default_pickup_location"] option[@selected="selected"]').attr('value').text rescue nil
    prefs["default_search"] = page.css('select[@name="opac.default_search_location"] option[@selected="selected"]').attr('value').text rescue nil
    prefs["keep_circ_history"] = to_bool(page.at('span:contains("circ_history")').next.next.text) rescue nil
    prefs["keep_hold_history"] = to_bool(page.at('span:contains("hold_history")').next.next.text) rescue nil
    prefs["email_notify"] = to_bool(page.css('input[@name="opac.hold_notify.email"]').attr('checked').try(:text)) rescue nil
    prefs["phone_notify"] = to_bool(page.css('input[@name="opac.hold_notify.phone"]').attr('checked').try(:text)) rescue nil
    prefs["text_notify"] = to_bool(page.css('input[@name="opac.hold_notify.sms"]').attr('checked').try(:text)) rescue nil
    prefs["phone_notify_number"] =  page.css('input[@name="opac.default_phone"]').attr('value').try(:text) rescue nil
    prefs["text_notify_number"] =  page.css('input[@name="opac.default_sms_notify"]').attr('value').try(:text) rescue nil
    return prefs
  end

  def update_user_info(args)
    if args['username']
      url = 'https://mr-v2.catalog.tadl.org/eg/opac/myopac/update_username'
      post_params = [["current_pw", args['password']], ["username", args['username']]]
    elsif args['new_password']
      url = 'https://mr-v2.catalog.tadl.org/eg/opac/myopac/update_password'
      post_params = [["current_pw", args['password']], ["new_pw", args['new_password']], ["new_pw2", args['new_password']]]
    elsif args['email']
      url = 'https://mr-v2.catalog.tadl.org/eg/opac/myopac/update_email'
      post_params = [["current_pw", args['password']], ["email", args['email']]]
    elsif args['hold_shelf_alias']
      url = 'https://mr-v2.catalog.tadl.org/eg/opac/myopac/update_alias'
      post_params = [["current_pw", args['password']], ["alias", args['hold_shelf_alias']]]
    else
      prefs = 'missing required parameters'
      message = 'missing required parameters'
      return prefs = 'missing required parameters'
    end
    agent = create_agent_token(self.token)
    agent.post(url, post_params)
    page = agent.page.parser
    test_for_bad_password =  page.at_css('div:contains("Your current password was not correct.")').text rescue nil
    test_for_in_use = page.at_css('div:contains("Please try a different username")').text rescue nil
    test_for_invalid_password = page.at_css('div:contains("New password is invalid")').text rescue nil
    test_for_invalid_email = page.at_css('div:contains("Please try a different email address")').text rescue nil
    test_for_alias_in_use = page.at_css('div:contains("Please try a different alias")').text rescue nil
    if test_for_bad_password != nil  
      message = "bad password"
      prefs = "bad password"
      user = self
    elsif test_for_in_use != nil
      message = "username is already taken"
      prefs = self.preferences
      user = self
    elsif test_for_invalid_password != nil
      message = "password does not meet requirements"
      prefs = self.preferences
      user = self
    elsif test_for_invalid_email != nil
      message = "invalid email address"
      prefs = self.preferences
      user = self
    elsif test_for_alias_in_use
      message = "alias in use"
      prefs = self.preferences
      user = self
    else
      message = "success"
      prefs = self.preferences
      if args['username'] 
        params = Hash.new
        params['username'] = args['username']
        params['password'] = args['password']
        user = User.new params
      elsif args['hold_shelf_alias']
        params = Hash.new
        params['username'] = self.username
        params['password'] = args['password']
        user = User.new params
      else
        user = self
      end 
    end
    return message, prefs, user
  end

  def update_notify_preferences(args)
    #make sure all the required params are passed or evergreen will process the missing as null
    if args['email_notify'] && args['phone_notify'] && args['text_notify'] && args['phone_notify_number'] && args['text_notify_number']
      agent = create_agent_token(self.token)
      url = 'https://mr-v2.catalog.tadl.org/eg/opac/myopac/prefs_notify'
      post_params = [
                      ["opac.hold_notify.email", args['email_notify']],
                      ["opac.hold_notify.phone", args['phone_notify']],
                      ["opac.hold_notify.sms", args['text_notify']],
                      ["opac.default_phone", args['phone_notify_number']],
                      ["opac.default_sms_notify", args['text_notify_number']]
                    ]
      agent.post(url , post_params)
      prefs = self.preferences
      self
    else
      prefs = 'missing required parameters'
    end
      return prefs
  end

  def update_search_history_preferences(args)
    if args['keep_hold_history'] && args['keep_circ_history'] && args['pickup_library'] && args['default_search']
      agent = create_agent_token(self.token)
      url = 'https://mr-v2.catalog.tadl.org/eg/opac/myopac/prefs_settings'
      post_params = [
                      ["opac.default_search_location", args['default_search']],
                      ["opac.default_pickup_location", args['pickup_library']],
                      ["history.circ.retention_start", args['keep_circ_history']],
                      ["history.hold.retention_start", args['keep_hold_history']],
                      ["opac.hits_per_page", '10']
                    ]
      agent.post(url, post_params)
      prefs = self.preferences
      self.default_search = args['default_search']
      self.pickup_library = args['pickup_library']
    else
      prefs = 'missing required parameters'
    end
      return prefs
  end

  def fines
  	agent = create_agent_token(self.token)
  	page = agent.get('https://mr-v2.catalog.tadl.org/eg/opac/myopac/main?limit=100')
  	fines_list = page.parser.css('#myopac_trans_div/table/tbody/tr').map do |c|
          {
            :transaction_start_date => c.css('td[1]').text.try(:strip),
            :last_pmt_date => c.css('td[2]').text.try(:strip),
            :initial_amt_owed => c.css('td[3]').text.try(:strip),
            :total_amt_paid => c.css('td[4]').text.try(:strip),
            :balance_owed => c.css('td[5]').text.try(:strip),
            :billing_type => c.css('td[6]').text.try(:strip),
          }
    end
    return fines_list
  end

  def payments
    agent = create_agent_token(self.token)
    page = agent.get('https://mr-v2.catalog.tadl.org/eg/opac/myopac/main_payments?limit=100')
    payment_list = page.parser.css('table[@title="Payments"]/tbody/tr').map do |c|
          {
            :payment_date => c.css('td[1]').text.try(:strip),
            :payment_for => c.css('td[2]').text.try(:strip),
            :amount => c.css('td[3]').text.try(:strip),
          }
    end
    return payment_list
  end

  def get_lists
    agent = create_agent_token(self.token)
    page = agent.get('https://mr-v2.catalog.tadl.org/eg/opac/myopac/lists')
    list_list = page.parser.css('.bookbag-controls-holder').map do |l|
      {
        :title=> l.css('.bookbag-name').try(:text) ,
        :description => l.css('.bookbag-description').try(:text),
        :list_id => l.search('input[@name="list"]')[0].try(:attr, "value").to_s,
        :shared => check_for_shared_list(l.css('.bookbag-share')),
        :default_list => check_for_default_list(l.search('input[@value="remove_default"]'))
      }
    end
    lists = Array.new
      list_list.each do |l|
        list = List.new l
        lists = lists.push(list)
      end
    return lists
  end

  def get_checkout_history(page)
    requested_page = (page.to_i * 30).to_s
    agent = create_agent_token(self.token)
    page = agent.get('https://mr-v2.catalog.tadl.org/eg/opac/myopac/circ_history?limit=30;offset=' + requested_page)
    checkouts = Array.new
    page.parser.css('#acct_checked_main_header').css('tr').each do |l|
      checkout = Hash.new
      checkout['title'] = l.css('td[1]/a[1]').try(:text).try(:strip)
      checkout['author'] = l.css('td[1]/a[2]').try(:text).try(:strip)
      checkout['record_id'] = l.at_css('td[1]/a[1]').try(:attr,'href').split('?')[0].gsub('/eg/opac/record/','') rescue nil
      checkout['checkout_date'] = l.css('td[2]').try(:text).try(:strip)
      checkout['due_date'] = l.css('td[3]').try(:text).try(:strip)
      checkout['return_date'] = l.css('td[4]').try(:text).try(:strip)
      checkout['barcode'] = l.css('td[5]').try(:text).try(:strip)
      checkouts = checkouts.push(checkout)
    end
    # remove first item in array because it is blank
    checkouts.shift()
    # check to see if there is a next page
    if page.parser.css('.invisible:contains("Next")').present?
      more_results = "false"
    else
      more_results = "true"
    end
    return checkouts, more_results
  end

  def get_hold_history(page)
    requested_page = (page.to_i * 15).to_s
    agent = create_agent_token(self.token)
    page = agent.get('https://mr-v2.catalog.tadl.org/eg/opac/myopac/hold_history?limit=15;offset=' + requested_page)
    holds = Array.new
    page.parser.css('#holds_main').css('tr').each do |l|
      hold = Hash.new
      hold['title'] = l.css('td[1]').try(:text).try(:strip)
      hold['author'] = l.css('td[2]').try(:text).try(:strip)
      hold['record_id'] = l.at_css('td[1]').css('a').try(:attr,'href').to_s.split('?')[0].gsub('/eg/opac/record/','') rescue nil
      hold['pickup_location'] = l.css('td[4]').try(:text).try(:strip)
      hold['active_on'] = l.css('td[5]').try(:text).try(:strip)
      hold['active'] = l.css('td[6]').try(:text).try(:strip)
      hold['date_fullfilled'] = l.css('td[7]').try(:text).try(:strip)
      # format for status info a real mess in ils, just return html value and then display as html in the view
      hold['status'] = l.css('td[8]').to_s rescue nil
      holds = holds.push(hold)
    end
    # remove first item in array because it is blank
    holds.shift()
    # check to see if there is a next page
    if page.parser.css('.invisible:contains("Next")').present?
      more_results = "false"
    else
      more_results = "true"
    end
    return holds, more_results
  end

  def check_for_shared_list(share_div)
    hidden = share_div.search('input[@name="action"]').try(:attr, "value").to_s
    if hidden != 'hide'
      return false
    else
      return true
    end
  end

  def check_for_default_list(default_value)
      if default_value.to_s != '' 
        return true
      else
        return false
      end
  end


  def circ_to_title(page, checkout_id)
  	look_for = 'input[@value="'+ checkout_id +'"]'
  	title = page.at(look_for).try(:parent).try(:next).try(:next).try(:css, 'a')[0].try(:text)
  	return title  
  end 

	def clean_record(string)
  	record_id = string.split('?') 
  	record_id = record_id[0].gsub('/eg/opac/record/','') 
  	return record_id
  end

  def scrape_checkouts(page)
  	checkouts_raw = page.parser.css('table#acct_checked_main_header').css('tr').drop(1).reject{|r| r.search('span[@class="failure-text"]').present?}.map do |c|
		  {
      :title => c.search('td[@name="author"]').css('a')[0].try(:text),
      :author => c.search('td[@name="author"]').css('a')[1].try(:text),
      :format => c.css('.marc_record_type').try(:text),
      :record_id => clean_record(c.search('td[@name="author"]').css('a')[0].try(:attr, "href")),
      :checkout_id => c.search('input[@name="circ"]').try(:attr, "value").to_s,
      :renew_attempts => c.search('td[@name="renewals"]').text.to_s.try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip),
      :due_date => c.search('td[@name="due_date"]').text.to_s.try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip),
     	:iso_due_date => Date.strptime(c.search('td[@name="due_date"]').text.to_s.try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip),'%m/%d/%Y').to_s,
      :barcode => c.search('td[@name="barcode"]').text.to_s.try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip),
    	}
    end
    checkouts = Array.new
  	checkouts_raw.each do |c|
  		checkout = Checkout.new c
  		checkouts = checkouts.push(checkout)
  	end
  	return checkouts
  end

  def to_bool(string)
      if string == "TRUE" || string == "checked"
          return true
      else
          return false
      end
  end

end
