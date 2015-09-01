Rails.application.routes.draw do
#  get 'errors/not_found'

#  get 'errors/internal_server_error'

  get "/404" => "errors#not_found"
  get "/500" => "errors#internal_server_error"

  root :to => "mock#index"
  get 'mock/index'
  match "mock/search" => "mock#search", via: [:get, :post], defaults: { format: 'html' }
  match "mock/login" => "mock#login", via: [:get, :post], defaults: { format: 'json' }
  match "mock/logout" => "mock#logout", via: [:get, :post], defaults: { format: 'json' }
  match "mock/place_hold" => "mock#place_hold", via: [:get, :post], defaults: { format: 'json' }
  match "mock/holds" => "mock#list_holds", via: [:get, :post], defaults: { format: 'html' }
  match "mock/checkouts" => "mock#list_checkouts", via: [:get, :post], defaults: { format: 'html' }
  match "mock/details" => "mock#details", via: [:get, :post], defaults: { format: 'html' }
  match "mock/manage_hold" => "mock#manage_hold", via: [:get, :post], defaults: { format: 'js' }
  match "mock/renew_checkouts" => "mock#renew_checkouts", via: [:get, :post], defaults: { format: 'js' }
  match "mock/marc" => "mock#marc", via: [:get, :post], defaults: { format: 'js' }
  match "mock/fines" => "mock#fines", via: [:get, :post], defaults: { format: 'html' }
  match "mock/payments" => "mock#payments", via: [:get, :post], defaults: { format: 'html' }
  match "mock/account" => "mock#account", via: [:get, :post], defaults: { format: 'html' }
  match "mock/preferences" => "mock#preferences", via: [:get, :post], defaults: { format: 'html' }
  match "mock/update_notifications" => "mock#update_notifications", via: [:get, :post], defaults: { format: 'json' }
  match "mock/update_search_history" => "mock#update_search_history", via: [:get, :post], defaults: {format: 'json'}
  match "mock/update_user_info" => "mock#update_user_info", via: [:get, :post], defaults: {format: 'json'}
  match "mock/edit_hold_pickup" => "mock#edit_hold_pickup", via: [:get, :post], defaults: {format: 'json'}
  match '/:action', :controller => 'mock', via: [:get, :post]







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
