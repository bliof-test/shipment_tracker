Rails.application.routes.draw do
  root 'home#index'

  get '/auth/auth0/callback', to: 'sessions#auth0_success_callback'
  post '/auth/developer/callback', to: 'sessions#auth0_success_callback'

  get '/auth/failure', to: 'sessions#auth0_failure_callback'
  delete '/sessions', to: 'sessions#destroy'

  # Events
  post 'events/:type', to: 'events#create', as: 'events'

  # Projections
  resource :feature_reviews, only: [:new, :show, :create] do
    get 'search'
    post 'link_ticket'
  end

  resources :releases, only: [:index, :show]

  resources :repositories,
    controller: 'git_repository_locations',
    as: 'git_repository_locations',
    only: [:index, :create]

  resources :tokens, only: [:index, :create, :update, :destroy]

  resources :github_notifications, only: [:create]
end
