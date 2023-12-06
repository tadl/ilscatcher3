Rails.application.routes.draw do
#  get 'errors/not_found'

#  get 'errors/internal_server_error'
    get "/404" => "errors#not_found", as: :not_found
    get "/500" => "errors#internal_server_error", as: :internal_server_error
    match "/util/youtube" => "util#youtube", via: [:get, :post]
    match "main/login" => "main#login", via: [:get, :post], defaults: { format: 'json' }
    match "main/logout" => "main#logout", via: [:get, :post], defaults: { format: 'json' }
    match "main/place_hold" => "main#place_hold", via: [:get, :post], defaults: { format: 'json' }
    match "main/holds" => "main#holds", via: [:get, :post], defaults: { format: 'html' }
    match "main/checkouts" => "main#checkouts", via: [:get, :post], defaults: { format: 'html' }
    match "main/manage_hold" => "main#manage_hold", via: [:get, :post], defaults: { format: 'js'}
    match "main/renew_checkouts" => "main#renew_checkouts", via: [:get, :post], defaults: { format: 'js' }
    match "main/fines" => "main#fines", via: [:get, :post], defaults: { format: 'html' }
    match "main/payments" => "main#payments", via: [:get, :post], defaults: { format: 'html' }
    match "main/account" => "main#account", via: [:get, :post], defaults: { format: 'html' }
    match "main/edit_preferences" => "main#edit_preferences", via: [:post], defaults: { format: 'js' }
    match "main/update_user_info" => "main#update_user_info", via: [:get, :post], defaults: {format: 'json'}
    match "main/password_reset" => "main#password_reset", via: [:get, :post], defaults: {format: 'html'}
    match "main/new_password_from_reset" => "main#new_password_from_reset", via: [:get, :post], defaults: {format: 'html'}
    match "main/confirm_password_reset" => "main#confirm_password_reset", via: [:get, :post], defaults: {format: 'js'}
    match "main/preferences" => "main#preferences", via: [:get, :post], defaults: { format: 'html' }
    match "main/update_notifications" => "main#update_notifications", via: [:get, :post], defaults: { format: 'json' }
    match "main/details" => "main#details", via: [:get, :post], defaults: { format: 'html' }
    match "main/marc" => "main#marc", via: [:get, :post], defaults: { format: 'js' }
    match "main/edit_hold_pickup" => "main#edit_hold_pickup", via: [:post], defaults: { format: 'js' }
    match "main/update_hold_pickup" => "main#update_hold_pickup", via: [:get, :post], defaults: {format: 'json'}
    match "main/checkout_history" => "main#checkout_history", via: [:get, :post], defaults: {format: 'html'}
    match "main/update_search_history" => "main#update_search_history", via: [:get, :post], defaults: {format: 'json'}
    match "main/login_hash" => "main#login_hash", via: [:get, :post], defaults: {format: 'json'}
    match "main/reset_password_request" => "main#reset_password_request", via: [:get, :post], defaults: {format: 'json'}
    match "main/show_qr" => "main#show_qr", via: [:post], defaults: { format: 'js' }
    match "main/card" => "main#card", via: [:get, :post], defaults: {format: 'html'}
  if Settings.account_only != 'true'
    root :to => "main#index"
    get 'main/index'
    get 'main/register'
    match "main/search" => "main#search", via: [:get, :post], defaults: { format: 'html' }
    match "main/index" => "main#index", via: [:get, :post], defaults: { format: 'html'}
    match "main/lists" => "main#lists", via: [:get, :post], defaults: { format: 'html' }
    match "main/view_list" => "main#view_list", via: [:get, :post], defaults: { format: 'html' }
    match "main/add_item_to_list" => "main#add_item_to_list", via: [:get, :post], defaults: { format: 'json' }
    match "main/remove_item_from_list" => "main#remove_item_from_list", via: [:get, :post], defaults: { format: 'json' }
    match "main/create_list" => "main#create_list", via: [:get, :post], defaults: { format: 'json' }
    match "main/destroy_list" => "main#destroy_list", via: [:get, :post], defaults: { format: 'json' }
    match "main/edit_list" => "main#edit_list", via: [:get, :post], defaults: { format: 'json' }
    match "main/add_note_to_list" => "main#add_note_to_list", via: [:get, :post], defaults: { format: 'json' }
    match "main/edit_note" => "main#edit_note", via: [:get, :post], defaults: { format: 'json' }
    match "main/share_list" => "main#share_list", via: [:get, :post], defaults: { format: 'json' }
    match "main/make_default_list" => "main#make_default_list", via: [:get, :post], defaults: { format: 'json' }
    match "main/hold_history" => "main#hold_history", via: [:get, :post], defaults: {format: 'json'}
    match "main/suggest_an_item" => "main#suggest_an_item", via: [:get, :post], defaults: {format: 'js'}
    match 'check_for_participant' => "summer_reading#check_for_participant", via: [:post], defaults: {format: 'json'}
    match 'main/melcat_frame' => "main#melcat_frame", via: [:get, :post]
    match "main/load_more_featured_items" => "main#load_more_featured_items", via: [:get, :post], defaults: {format: 'js'}
    match '*path', to: 'application#preflight', via: :options
    match '/:action', :controller => 'main', via: [:get, :post]
    #handle legacy item details links
    match '/eg/opac/record/:id' => redirect('/main/details?id=%{id}'), via: [:get, :post]
    #handle legarcy password reset request
    match 'eg/opac/password_reset' => redirect('/main/password_reset'), via: [:get, :post]
    #handle legacy searches
    match '/eg/opac/results' => "util#rewrite_legacy_search", via: [:get, :post]
    #handle legacy advanced search
    match '/eg/opac/advanced' => redirect('/main/search'), via: [:get, :post]
    #handle legacy home
    match '/eg/opac/home' => "util#rewrite_legacy_home", via: [:get, :post]
    #handle legacy account stuff
    match '/eg/opac/myopac/main' =>  "util#rewrite_legacy_account", via: [:get, :post], defaults: { format: 'html' }
    #handle legacy account stuff
    match '/eg/opac/myopac/holds' =>  "util#rewrite_legacy_holds", via: [:get, :post], defaults: { format: 'html' }
    #handle legacy account stuff
    match '/eg/opac/myopac/circs' =>  "util#rewrite_legacy_checkouts", via: [:get, :post], defaults: { format: 'html' }
    #handle legacy account stuff
    match '/eg/opac/login' =>  "util#rewrite_legacy_account", via: [:get, :post], defaults: { format: 'html' }
    #handle legacy reset password
    match '/eg/opac/password_reset/:token' => redirect('/main/new_password_from_reset?token=%{token}'), via: [:get, :post]
    #handle unsupported links
    match '/eg/opac/mylist/add' => "util#rewrite_legacy_home", via: [:get, :post]
    match '/eg/opac/place_hold' => "util#rewrite_legacy_home", via: [:get, :post]
  else
    root :to => "main#checkouts"
    match "main/index" => "main#checkouts", via: [:get, :post], defaults: { format: 'html'}
    match "login" => "main#login", via: [:get, :post], defaults: {format: 'json'}
    match "logout" => "main#logout", via: [:get, :post], defaults: {format: 'js'}
  end
  if Settings.has_registration == 'true'
    match "/register/new" => "main#patron_register", via: [:get, :post], defaults: { format: 'html' }
  end
  if Settings.has_kiosk == true
    get 'main/kiosk'
  end
end
