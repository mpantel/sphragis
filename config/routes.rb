# frozen_string_literal: true

Sphragis::Engine.routes.draw do
  resources :documents, only: [] do
    member do
      get :preview
      get :view
      post :sign
      get :validate_placement
    end
  end

  # Convenience routes
  get "preview", to: "documents#preview"
  get "view", to: "documents#view"
  post "sign", to: "documents#sign"
end
