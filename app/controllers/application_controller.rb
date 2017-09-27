class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    require 'open-uri'
    require 'digest/md5'
    before_filter :set_headers
    rescue_from Mechanize::Error, with: :scrape_error
    rescue_from SocketError, with: :scrape_error

    def set_headers
        headers['Access-Control-Allow-Origin'] = '*'      
    end  

    def shared_main_variables
        @logo = Settings.logo
        @query_options = [['Keyword', 'keyword'], ['Author / Group / Actor', 'author'],['Title', 'title'],['Subject', 'subject'], ['Series', 'series'], ['Genre', 'single_genre'], ['Call Number', 'call_number']]
        @format_options = Settings.format_options
        @format_options_unlocked = Settings.format_options_unlocked
        @format_default = Settings.format_options[0][2]
        @sort_options = [['Relevance', 'relevancy'], ['Newest to Oldest', 'pubdateDESC'],['Oldest to Newest', 'pubdateASC'],['Title A to Z', 'titleAZ'], ['Title Z to A', 'titleZA']]
        @location_options = Settings.location_options
        @pickup_locations = Settings.pickup_locations
        @long_pickup_locations = Settings.long_pickup_locations
        @this_site = Settings.opac_toggle_default
        @truefalseicons = [['glyphicon glyphicon-ok text-success', true], ['glyphicon glyphicon-remove text-danger', false]]
    	@format_icons = [['a','glyphicon-book','text'], 
                        ['c','glyphicon-music','notated music'], 
                        ['d','glyphicon-music','notated music'], 
                        ['e','glyphicon-globe','cartographic'], 
                        ['f','glyphicon-globe','cartographic'], 
                        ['g','glyphicon-film','moving image'], 
                        ['i','glyphicon-cd','sound recording-nonmusical'], 
                        ['j','glyphicon-cd','sound recording-musical'], 
                        ['k','glyphicon-picture','still image'], 
                        ['m','glyphicon-file','software, multimedia'], 
                        ['o','glyphicon-briefcase','kit'], 
                        ['p','glyphicon-briefcase','mixed-material'], 
                        ['r','glyphicon-inbox','three dimensional object'],
                        ['t','glyphicon-book','text']
                    ]
    end

    def generate_user()
        if cookies[:login]
            args = Hash.new
            args['token'] = cookies[:login]
            user = User.new args
        else
            user = User.new params
        end
        if user.lists
            cookies[:lists] = {:value => user.lists.to_json}
        else
            cookies.delete :lists
        end
        return user
    end


    def set_cookies(user)
      cookies[:login] = { :value => user.token, :expires => 2.hours.from_now }
      cookies[:user] = {:value => user.to_json, :expires => 2.hours.from_now }
    end

    def scrape_error
        respond_to do |format|
            format.js  {render :js => "alert_message('danger', 'An error occured. Please try again later.', 10000);" }
            format.html {redirect_to internal_server_error_path}
        end
    end

    def request_password_reset
        agent = Mechanize.new
        user = params["username"]
        url = 'https://' + Settings.machine_readable + '/eg/opac/password_reset'
        page = agent.get(url)
        form = page.forms[1]
        if (user =~ /^TADL\d{7,8}$|^90\d{5}$|^91111\d{9}$|^[a-zA-Z]\d{10}/ )
          form.field_with(:name => "barcode").value = user
        else
          form.field_with(:name => "username").value = user
        end
        agent.submit(form)
        return 'complete'
    end

    def fire_password_reset(token, password_1, password_2)
        agent = Mechanize.new
        url = 'https://' + Settings.machine_readable + '/eg/opac/password_reset/' + token
        page = agent.post(url, {'uuid' => token, 'pwd1' => password_1, 'pwd2' => password_2})
        check_for_error = page.parser.css('#main-content/p.error').text
        if check_for_error != ''
            confirmation = check_for_error
        else
            confirmation = 'good'
        end
        return confirmation
    end

    def login_refresh_action(username, pass_md5)
      uri = URI.parse('https://' + Settings.machine_readable + "/osrf-gateway-v1")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request_seed = Net::HTTP::Post.new(uri.request_uri)
      request_seed.set_form_data({
          "service" => "open-ils.auth",
          "method" => "open-ils.auth.authenticate.init",
          "param" => '"' + username + '"'
      })
      response = http.request(request_seed)
      # ensure http status ok, ensure json status ok
      if response.code == '200'
          j_content = JSON.parse(response.body)
          if j_content['status'] == 200
              seed = j_content['payload'][0]
          end
      end
      password = Digest::MD5.hexdigest(seed + pass_md5)
      auth_param = {
          "type" => "opac",
          "password" => password
      }
      if ( username =~ /^TADL\d{7,8}$|^90\d{5}$|^91111\d{9}$|^[a-zA-Z]\d{10}/ )
          auth_param["barcode"] = username
      else
          auth_param["username"] = username
      end
      request_complete = Net::HTTP::Post.new(uri.request_uri)
      request_complete.set_form_data({
          "service" => "open-ils.auth",
          "method" => "open-ils.auth.authenticate.complete",
          "param" => JSON.generate(auth_param)
      })
      response = http.request(request_complete)
      if response.code == '200'
          j_content = JSON.parse(response.body)
          if j_content['status'] == 200
              if j_content['payload'][0]['ilsevent'] == 0
                  return j_content['payload'][0]['payload']['authtoken']
              end
          end
      end
    end
end