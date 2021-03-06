ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  map.connect "",           :controller => "main", :action => "home"
  map.connect "home",       :controller => "main", :action => "home"
  map.connect "news",       :controller => "main", :action => "news"
  map.connect "search",     :controller => "main", :action => "search"
  map.connect "references", :controller => "main", :action => "references"
  map.connect "contact",    :controller => "main", :action => "contact"

  map.resources :structures,
                :member     => { :jmol => :get },
                :collection => { :search => :get }

  map.resources :interfaces
                #:collection => { :search => :get }

  map.resources(:scops,
                :singular => "scop",
                :member => {
                  :jmol           => :get,
                  :domains        => :get,
                },
                :collection => {
                  :search   => :get,
                  :set      => :get
                })

  map.resources(:alignments, :member => { :jalview => :get })

  #map.resources :gos,
  #              :singular => "go",
  #              :member => { :hierarchy => :get },
  #              :collection => { :search => :get }

  #map.resources :taxa,
  #              :singular => "taxon",
  #              :collection => { :search => :get }

  #map.resources :fugue_searches

  #map.resources :interface_searches

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
