# frozen_string_literal: true

basedir = File.expand_path('lib', __dir__)
libraries =
  [
    'redmine_mcp_server/message',
    'redmine_mcp_server/session',
  ]

libraries.each do |library|
  require_dependency File.expand_path(library, basedir)
end

Redmine::Plugin.register :redmine_mcp_server do
  name 'MCP Server Plugin'
  author '9506hqwy'
  description 'This is a Model Context Protocol server for Redmine'
  version '0.2.0'
  url 'https://github.com/9506hqwy/redmine_mcp_server'
  author_url 'https://github.com/9506hqwy'
end
