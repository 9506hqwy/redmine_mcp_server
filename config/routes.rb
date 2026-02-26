# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  resources :projects do
    post '/mcp', to: 'mcp#handle', format: false
    get '/mcp', to: 'mcp#notify', format: false
    delete '/mcp', to: 'mcp#terminate', format: false
  end
end
