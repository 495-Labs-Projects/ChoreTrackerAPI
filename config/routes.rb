Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :children
  resources :tasks
  resources :chores
  resources :users

  get :token, controller: 'application'
end
