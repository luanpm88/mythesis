Mythesis2::Application.routes.draw do
  resources :test_article_attribute_sentences

  resources :attribute_values

  resources :attributes

  resources :infobox_templates

  resources :articles do
    collection do
      get :import
      get :create_raw_attribute_value
      get :create_senteces_file
      get :write_article_to_files
      get :find_sentences_with_value
      get :create_doccat_training_file
      get :train_doccat
      get :create_vector_space_for_attribute
      get :create_train_for_filter_by_cluster
      get :create_training_data_for_CRF
      get :training_CRF
      get :doccat_test_files
      get :filter
      get :create_test_files_crf
      get :test_CRF
    end
  end

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
