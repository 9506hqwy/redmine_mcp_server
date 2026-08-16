# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  resources :projects do
    post '/mcp', to: 'mcp#handle', format: false
  end
end
