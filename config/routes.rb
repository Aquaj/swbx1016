Rails.application.routes.draw do
  root controller: :features, action: :index, as: :swag
end
