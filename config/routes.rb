Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  namespace :v1 do
    get "health"
    get "companies", to: "companies#show"

    namespace :ov do
      get "submissions", to: "submissions#show"
      post "submissions", to: "submissions#create"
      delete "submissions/:id", to: "submissions#destroy"
    end
  end

  defaults format: :json do
    namespace :v2 do
      get "companies", to: "companies#index"

      namespace :ov do
        resources :submissions
      end
    end
  end
end
