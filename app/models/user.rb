class User
	include ActiveModel::Model
	require 'open-uri'
	attr_accessor :full_name, :checkouts, :holds, :holds_ready, :fine, :token, :card, :error

	def initialize args
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

	def create_agent_token(token)
		agent = Mechanize.new
		cookie = Mechanize::Cookie.new('ses', token)
		cookie.domain = 'mr.tadl.org'
		cookie.path = '/'
		agent.cookie_jar.add!(cookie)
		return agent
	end

	def create_agent_username_password(username, password)
		agent = Mechanize.new
		agent.get('https://mr.tadl.org/eg/opac/myopac/prefs')
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
				page = agent.get('https://mr.tadl.org/eg/opac/myopac/prefs')
			end
			basic_info = Hash.new
			page.parser.css('body').each do |p|
				basic_info['full_name'] = p.css('span#dash_user').try(:text).strip rescue nil
				basic_info['checkouts'] =  p.css('span#dash_checked').try(:text).strip rescue nil
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
		# TODO: handle holds that require force
        # such as: "Placing this hold could result in longer wait times."
		record_ids = record_id.split(',').reject(&:empty?).map(&:strip).map {|k| "&hold_target=#{k}" }.join
		agent = create_agent_token(self.token)
		agent.get('https://mr.tadl.org/eg/opac/place_hold?hold_type=T' + record_ids)
		hold_form = agent.page.forms[1]
		agent.submit(hold_form)
		confirmation_messages = agent.page.parser.css('//table#hold-items-list//tr').map do |m|
  			{
  				:record_id => m.at_css("td[1]//input").try(:attr, "value"),
  			   	:message => m.at_css("td[2]").try(:text).try(:gsub!, /\n/," ").try(:squeeze, " ").try(:strip).try(:split, ". ").try(:last),
  			}
  		end
  		return confirmation_messages
	end

	def list_holds
		agent = create_agent_token(self.token)
		page = agent.get('https://mr.tadl.org/eg/opac/myopac/holds?limit=41')
		holds_raw = page.parser.css('tr#acct_holds_temp').map do |h|
			{
        	:title =>  h.css('td[2]').css('a').text,
        	:author => h.css('td[3]').css('a').text,
        	:record_id => clean_record(h.css('td[2]').css('a').try(:attr, 'href').to_s),
        	:hold_id => h.search('input[@name="hold_id"]').try(:attr, "value").to_s,
        	:hold_status => h.css('td[8]').text.strip,
        	:queue_status => h.css('/td[9]/div/div[1]').text.strip.gsub(/AvailableExpires/, 'Available, Expires'),
        	:queue_state => h.css('/td[9]/div/div[2]').text.scan(/\d+/).map { |n| n.to_i },
        	:pickup_location => h.css('td[5]').text.strip,
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

	def clean_record(string)
  		record_id = string.split('?') rescue nil
  		record_id = record_id[0].gsub('/eg/opac/record/','') rescue nil
  		return record_id
  	end
end
