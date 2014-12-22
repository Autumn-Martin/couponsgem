Couponing::Engine.routes.draw do
  resources :coupons do
    collection do
      get 'test'
      get 'apply'
      get 'redeem'
    end
  end
end