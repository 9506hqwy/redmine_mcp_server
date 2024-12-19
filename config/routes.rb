# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  resources :projects do
    get '/mcp/sse', to: 'mcp#sse', format: false
    post '/mcp/messages', to: 'mcp#messages', format: false
  end
end
