Rails.application.routes.draw do
  devise_for :users

  namespace :admin do
    resources :billing, only: [ :index ]
    resources :email_lists, only: [ :index ]
    resource :user_settings, only: [ :edit ]

    namespace :intake do
      resources :conversations, only: [ :index, :show ] do
        member do
          post :take_over
          post :release
          post :mark_complete
          post :mark_abandoned
        end
        resources :messages, only: [ :create ]
      end
      resources :leads, only: [ :index, :show, :edit, :update ]
      resource :general_settings, only: [ :edit, :update ]
      resource :quiet_hours_settings, only: [ :edit, :update ]
      resource :chatbot_config, only: [ :edit, :update ]
    end
  end

  namespace :webhooks do
    post "twilio/whatsapp", to: "twilio#whatsapp"
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # Root: redirect to admin if signed in, otherwise to Devise sign-in.
  authenticated :user do
    root to: redirect("/admin/intake/conversations"), as: :authenticated_root
  end
  root to: redirect("/users/sign_in")
end
