Rails.application.routes.draw do
#  get 'errors/not_found'

#  get 'errors/internal_server_error'

  get "/404" => "errors#not_found", as: :not_found
  get "/500" => "errors#internal_server_error", as: :internal_server_error

  match "/util/youtube" => "util#youtube", via: [:get, :post]

  root :to => "main#index"
  get 'main/index'
  match "main/search" => "main#search", via: [:get, :post], defaults: { format: 'html' }
  match "main/login" => "main#login", via: [:get, :post], defaults: { format: 'json' }
  match "main/logout" => "main#logout", via: [:get, :post], defaults: { format: 'json' }
  match "main/place_hold" => "main#place_hold", via: [:get, :post], defaults: { format: 'json' }
  match "main/holds" => "main#holds", via: [:get, :post], defaults: { format: 'html' }
  match "main/checkouts" => "main#checkouts", via: [:get, :post], defaults: { format: 'html' }
  match "main/details" => "main#details", via: [:get, :post], defaults: { format: 'html' }
  match "main/manage_hold" => "main#manage_hold", via: [:get, :post], defaults: { format: 'js' }
  match "main/renew_checkouts" => "main#renew_checkouts", via: [:get, :post], defaults: { format: 'js' }
  match "main/marc" => "main#marc", via: [:get, :post], defaults: { format: 'js' }
  match "main/fines" => "main#fines", via: [:get, :post], defaults: { format: 'html' }
  match "main/payments" => "main#payments", via: [:get, :post], defaults: { format: 'html' }
  match "main/account" => "main#account", via: [:get, :post], defaults: { format: 'html' }
  match "main/edit_preferences" => "main#edit_preferences", via: [:post], defaults: { format: 'js' }
  match "main/preferences" => "main#preferences", via: [:get, :post], defaults: { format: 'html' }
  match "main/lists" => "main#lists", via: [:get, :post], defaults: { format: 'html' }
  match "main/fetch_list" => "main#fetch_list", via: [:get, :post], defaults: { format: 'html' }
  match "main/add_item_to_list" => "main#add_item_to_list", via: [:get, :post], defaults: { format: 'json' }
  match "main/remove_item_from_list" => "main#remove_item_from_list", via: [:get, :post], defaults: { format: 'json' }
  match "main/create_list" => "main#create_list", via: [:get, :post], defaults: { format: 'json' }
  match "main/destroy_list" => "main#destroy_list", via: [:get, :post], defaults: { format: 'json' }
  match "main/edit_list" => "main#edit_list", via: [:get, :post], defaults: { format: 'json' }
  match "main/add_note_to_list" => "main#add_note_to_list", via: [:get, :post], defaults: { format: 'json' }
  match "main/edit_note" => "main#edit_note", via: [:get, :post], defaults: { format: 'json' }
  match "main/share_list" => "main#share_list", via: [:get, :post], defaults: { format: 'json' }
  match "main/make_default_list" => "main#make_default_list", via: [:get, :post], defaults: { format: 'json' }
  match "main/update_notifications" => "main#update_notifications", via: [:get, :post], defaults: { format: 'json' }
  match "main/update_search_history" => "main#update_search_history", via: [:get, :post], defaults: {format: 'json'}
  match "main/update_user_info" => "main#update_user_info", via: [:get, :post], defaults: {format: 'json'}
  match "main/edit_hold_pickup" => "main#edit_hold_pickup", via: [:post], defaults: { format: 'js' }
  match "main/update_hold_pickup" => "main#update_hold_pickup", via: [:get, :post], defaults: {format: 'json'}
  match "main/checkout_history" => "main#checkout_history", via: [:get, :post], defaults: {format: 'html'}
  match "main/hold_history" => "main#hold_history", via: [:get, :post], defaults: {format: 'json'}
  match '/:action', :controller => 'main', via: [:get, :post]
end
