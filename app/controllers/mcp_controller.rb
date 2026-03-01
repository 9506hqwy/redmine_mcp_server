# frozen_string_literal: true

# TODO: Check Origin header

class McpController < ApplicationController
  protect_from_forgery except: [:handle, :terminate]

  before_action :valid_accept_header,
                :valid_version_header,
                :find_project_by_project_id
  before_action :parse_jsonrpc_request, only: :handle
  before_action :find_or_create_session_by_header, only: [:handle, :terminate]

  def handle
    res = @session.handle(@jsonrpc)

    if @initialize
      response.headers['MCP-Session-Id'] = @session.id
    end

    if res
      render_api(:ok, res)
    else
      render_api_head(:accepted)
    end
  end

  def notify
    render_api_head(:method_not_allowed)
  end

  def terminate
    @session.close

    render_api_head(:ok)
  end

  def valid_accept_header
    accepts = request.headers["Accept"]
    if contains_value(accepts, "application/json")
      # Support
    elsif contains_value(accepts, "text/event-stream")
      render_api_head(:method_not_allowed)
    else
      render_api_head(:bad_request)
    end
  end

  def valid_version_header
    version = request.headers["MCP-Protocol-Version"]
    if version && version != RedmineMcpServer::Message::PROTOCOL_VERSION
      render_api_head(:bad_request)
    end
  end

  def parse_jsonrpc_request
    body = request.body.read.chomp("\"")
    @jsonrpc = JSON.parse(body, symbolize_names: true)
    @initialize = @jsonrpc[:method] == "initialize"
  rescue JSON::ParserError => e
    Rails.logger.error(e)
    error = RedmineMcpServer::Message.err_parse
    render_api(:bad_request, error)
  end

  def find_or_create_session_by_header
    @session = nil

    if @initialize
      @session = RedmineMcpServer::Session.new(@project, 180)
    else
      session_id = request.headers["MCP-Session-Id"]
      @session = RedmineMcpServer::Session.get(session_id) if session_id

      if session_id.nil?
        error = RedmineMcpServer::Message.err_invalid_request(@jsonrpc&.[](:id))
        render_api(:bad_request, error)
      elsif @session.nil?
        error = RedmineMcpServer::Message.err_generic(@jsonrpc&.[](:id))
        render_api(:not_found, error)
      end
    end
  end

  def contains_value(values, value)
    values.split(",").map{|a| a.strip}.include?(value)
  end

  def render_api(status, content)
    response.headers['Content-Type'] = "application/json"
    render(json: content, status: status)
  end
end
