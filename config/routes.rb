Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  root "static_pages#top"
  get "how_to_use", to: "static_pages#how_to_use"
  resource :simulations, only: %i[new]
  post "combat_roll", to: "simulations#combat_roll"
  resources :characters
  resource :tutorial, only: [ :update ]

  # Defines the root path route ("/")
  # root "posts#index"
  # letter_opnere_web用設定
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
