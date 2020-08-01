Rails.application.routes.draw do
  resources :votes
  resources :proposed_solutions
  resources :participants
  resources :challenges
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
