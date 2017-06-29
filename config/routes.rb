Rails.application.routes.draw do
  get 'bot/index'

  get 'bot/show'

  get 'bot/create'
  get 'bot/previous'
  get 'bot/fx'
  get 'bot/beneficiary'
  get 'bot/design'
  get 'bot/existing'
  post 'bot/new'
  post 'bot/login'
  post 'bot/start'
  root 'bot#index'
  get 'bot/fx_back'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
