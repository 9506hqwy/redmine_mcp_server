# frozen_string_literal: true

# TODO: Check Origin header

class McpController < ApplicationController
  protect_from_forgery except: [:handle]

  before_action :valid_accept_header,
                :find_mcp_headers,
                :find_project_by_project_id
  before_action :parse_jsonrpc_request, only: :handle

  def handle
    session = RedmineMcpServer::Session.new(@project)

    headers = {
      protocol_version: @mcp_protocol_version,
      method: @mcp_method,
      name: @mcp_name
    }
    status, res = session.handle(@jsonrpc, headers)

    if res
      render_api(status, res)
    else
      render_api_head(status)
    end
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

  def find_mcp_headers
    @mcp_protocol_version = request.headers["MCP-Protocol-Version"]
    @mcp_method = request.headers["MCP-Method"]
    @mcp_name = request.headers["MCP-Name"]
  end

  def parse_jsonrpc_request
    body = request.body.read.chomp("\"")
    @jsonrpc = JSON.parse(body, symbolize_names: true)
  rescue JSON::ParserError => e
    Rails.logger.error(e)
    error = RedmineMcpServer::Message.err_parse
    render_api(:bad_request, error)
  end

  def contains_value(values, value)
    values.split(",").map{|a| a.strip}.include?(value)
  end

  def render_api(status, content)
    response.headers['Content-Type'] = "application/json"
    render(json: content, status: status)
  end
end
