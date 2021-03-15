Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  namespace :v1 do
    get "health"

    namespace :ov do
      get "submissions", to: "submissions#show"
      post "submissions", to: "submissions#create"
      delete "submissions/:id", to: "submissions#destroy"
    end
  end
end
