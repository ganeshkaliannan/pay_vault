Rails.application.routes.draw do
  resources :payouts, only: [ :index, :new, :create, :show ]
  resources :beneficiaries do
    member do
      post "verify"
    end
  end
  # Merchants (Admin only)
  resources :merchants do
    member do
      get "add_funds"
      post "fund"
    end
  end

  devise_for :users, path: "/", path_names: {
    sign_in: "login",
    sign_out: "logout",
    sign_up: "register",
    edit: "profile"
  }, controllers: {
    sessions: "users/sessions",
    registrations: "users/registrations",
    passwords: "users/passwords"
  }

  # Application routes
  get "/payments", to: "payments#index"
  get "/transactions", to: "transactions#index"
  get "/settings", to: "settings#index"
  get "/settings/security", to: "settings#security"
  get "/settings/payout", to: "settings#payout"
  get "/settings/notifications", to: "settings#notifications"
  get "/settings/bank_accounts", to: "settings#bank_accounts"

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "dashboard#index"
end
