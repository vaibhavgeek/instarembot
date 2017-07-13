Rails.application.routes.draw do
  get 'bot/index'
  get 'bot/need_transact'
   get 'bot/need_regis'
  get 'bot/need_misc'
  get 'bot/need_offers'


  get 'bot/get_transaction_status'
  post 'bot/submit_transaction'
  get 'bot/show'
  get 'bot/info_tags'
  get 'bot/create'
  get 'bot/previous'
  post 'bot/fx'
  get 'bot/beneficiary'
  get 'bot/design'
  get 'bot/existing'
  post 'bot/new'
  post 'bot/login'
  post 'bot/start'
  root 'bot#index'
  get 'bot/fx_back'
  post 'bot/logout'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
