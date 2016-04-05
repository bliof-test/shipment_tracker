# frozen_string_literal: true
Rails.application.routes.draw do
  root 'home#index'

  get '/heartbeat', to: 'heart_beat#index'

  get '/auth/auth0/callback', to: 'sessions#auth0_success_callback'
  post '/auth/developer/callback', to: 'sessions#auth0_success_callback'

  get '/auth/failure', to: 'sessions#auth0_failure_callback'
  delete '/sessions', to: 'sessions#destroy'

  post 'events/:type', to: 'events#create', as: 'events'

  resource :feature_reviews, only: [:new, :show, :create] do
    post 'link_ticket'
  end

  resources :releases, only: [:index, :show]

  resources :repositories, only: [:index, :create],
                           controller: 'git_repository_locations', as: 'git_repository_locations'

  resources :tokens, only: [:index, :create, :update, :destroy]

  resources :github_notifications, only: [:create]
end
