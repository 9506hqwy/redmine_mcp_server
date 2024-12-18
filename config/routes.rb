# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  resources :projects do
    get '/event/sse', to: 'event#sse', format: false
    post '/event/messages', to: 'event#messages', format: false
  end
end
