Rails.application.routes.draw do
  resources :administrators, only: :create do
    post :login, on: :collection
    post :logout, on: :collection
  end

  namespace :admin do
    resources :challenges do
      post 'open_voting', on: :member
      post 'next_round', on: :member
      post 'reset', on: :member
    end
  end

  resources :challenges, only: :show do
    resources :participants, only: :create
    resources :votes, only: :update
    resources :proposed_solutions
  end

  get :privacy, controller: :home

  root to: "home#index"
end
