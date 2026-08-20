Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "auth/sessions#new"

  get "/termos-de-uso", to: "legal#terms", as: "terms"

  namespace :auth, as: "", path: "" do
    get "/login", to: "sessions#new", as: "new_session"
    post "/login", to: "sessions#create", as: "session"
    delete "/logout", to: "sessions#destroy", as: "destroy_session"
  end

  namespace :users do
    root "home#dashboard"
  end

  get "/users/reservations", to: "users/reservations#index", as: :users_reservations_path
  get "/users/reservations/new", to: "users/reservations#new", as: :new_users_reservation
  get "/users/reservations/new/space", to: "users/reservations#step", defaults: { step: "space" }, as: :new_users_reservation_space
  get "/users/reservations/new/schedule", to: "users/reservations#step", defaults: { step: "schedule" }, as: :new_users_reservation_schedule
  get "/users/reservations/new/confirmation", to: "users/reservations#step", defaults: { step: "confirmation" }, as: :new_users_reservation_confirmation
  patch "/users/reservations/new/:step", to: "users/reservations#update", constraints: {
    step: Regexp.union(Reservations::ReservationForm::STEPS.map(&:to_s))
  }, as: :users_reservation_step
  post "/users/reservations", to: "users/reservations#create", as: :users_reservations
end
