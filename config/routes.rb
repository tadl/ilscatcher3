Rails.application.routes.draw do
#  get 'errors/not_found'

#  get 'errors/internal_server_error'

  get "/404" => "errors#not_found", as: :not_found
  get "/500" => "errors#internal_server_error", as: :internal_server_error

  root :to => "main#index"
  get 'main/index'
  match "main/search" => "main#search", via: [:get, :post], defaults: { format: 'html' }
  match "main/login" => "main#login", via: [:get, :post], defaults: { format: 'json' }
  match "main/logout" => "main#logout", via: [:get, :post], defaults: { format: 'json' }
  match "main/place_hold" => "main#place_hold", via: [:get, :post], defaults: { format: 'json' }
  match "main/holds" => "main#list_holds", via: [:get, :post], defaults: { format: 'html' }
  match "main/checkouts" => "main#list_checkouts", via: [:get, :post], defaults: { format: 'html' }
  match "main/details" => "main#details", via: [:get, :post], defaults: { format: 'html' }
  match "main/manage_hold" => "main#manage_hold", via: [:get, :post], defaults: { format: 'js' }
  match "main/renew_checkouts" => "main#renew_checkouts", via: [:get, :post], defaults: { format: 'js' }
  match "main/marc" => "main#marc", via: [:get, :post], defaults: { format: 'js' }
  match "main/fines" => "main#fines", via: [:get, :post], defaults: { format: 'html' }
  match "main/payments" => "main#payments", via: [:get, :post], defaults: { format: 'html' }
  match "main/account" => "main#account", via: [:get, :post], defaults: { format: 'html' }
  match "main/preferences" => "main#preferences", via: [:get, :post], defaults: { format: 'html' }
  match "main/user_lists" => "main#user_lists", via: [:get, :post], defaults: { format: 'json' }
  match "main/update_notifications" => "main#update_notifications", via: [:get, :post], defaults: { format: 'json' }
  match "main/update_search_history" => "main#update_search_history", via: [:get, :post], defaults: {format: 'json'}
  match "main/update_user_info" => "main#update_user_info", via: [:get, :post], defaults: {format: 'json'}
  match "main/edit_hold_pickup" => "main#edit_hold_pickup", via: [:get, :post], defaults: {format: 'json'}
  match "main/list_checkout_history" => "main#list_checkout_history", via: [:get, :post], defaults: {format: 'json'}
  match "main/list_hold_history" => "main#list_hold_history", via: [:get, :post], defaults: {format: 'json'}
  match '/:action', :controller => 'main', via: [:get, :post]







  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
