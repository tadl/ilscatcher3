class User
	include ActiveModel::Model
	require 'open-uri'
	attr_accessor :full_name, :checkouts, :holds, :holds_ready, :fine, :token, :card, :error

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
		agent.get('https://mr-v2.catalog.tadl.org/eg/opac/myopac/prefs')
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
				page = agent.get('https://mr-v2.catalog.tadl.org/eg/opac/myopac/prefs')
			end
			basic_info = Hash.new
			page.parser.css('body').each do |p|
				basic_info['full_name'] = p.css('span#dash_user').try(:text).strip rescue nil
				basic_info['checkouts'] =  p.css('#dash_checked').try(:text).strip rescue nil
				basic_info['holds'] =  p.css('span#dash_holds').try(:text).strip rescue nil
				basic_info['holds_ready'] = p.css('span#dash_pickup').try(:text).strip rescue nil
				basic_info['fine'] = p.css('span#dash_fines').try(:text).strip.gsub(/\$/, '') rescue nil
				basic_info['card'] = p.at('td:contains("Active Barcode")').try(:next_element).try(:text) rescue nil
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
    submit_forced_hold = agent.submit(hold_form)
    confirmation_messages = process_hold_confirmations(submit_forced_hold)
    return confirmation_messages
  end

  def process_hold_confirmations(page)
    confirmation_messages = page.parser.css('//table#hold-items-list//tr').map do |m|
      {
        :record_id => m.at_css("td[1]//input").try(:attr, "value"),
        :message => m.at_css("td[2]").try(:text).try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip).try(:split, ". ").try(:last),
      }
    end
    confirmation_messages.each do |c|
      if c[:message] != "Hold was successfully placed"
        c[:error] = true
        if c[:message] == "Placing this hold could result in longer wait times." 
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
        	:format => h.css('.format_icon').css('img').try(:attr, "title").text,
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

	def manage_hold(hold)
		agent = create_agent_token(self.token)
		agent.post('https://mr-v2.catalog.tadl.org/eg/opac/myopac/holds?limit=41',[["action", hold.task],["hold_id", hold.hold_id]])
		holds = self.list_holds
		updated_details = self.basic_info(agent)
    user = User.new updated_details
		return holds, user
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

  def circ_to_title(page, checkout_id)
  	look_for = 'input[@value="'+ checkout_id +'"]'
  	title = page.at(look_for).try(:parent).try(:next).try(:next).try(:css, 'a')[0].try(:text)
  	return title  
  end 

	def clean_record(string)
  	record_id = string.split('?') rescue nil
  	record_id = record_id[0].gsub('/eg/opac/record/','') rescue nil
  	return record_id
  end

  def scrape_checkouts(page)
  	checkouts_raw = page.parser.css('table#acct_checked_main_header').css('tr').drop(1).reject{|r| r.search('span[@class="failure-text"]').present?}.map do |c|
		  {
      :title => c.search('td[@name="author"]').css('a')[0].try(:text),
      :author => c.search('td[@name="author"]').css('a')[1].try(:text),
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

end
