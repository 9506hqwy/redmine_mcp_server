# frozen_string_literal: true

class McpController < ApplicationController
  include ActionController::Live

  protect_from_forgery except: :messages

  before_action :find_project_by_project_id

  @@sessions = {}

  def sse
    response.headers['Content-Type'] = 'text/event-stream'
    response.headers['Last-Modified'] = Time.now.httpdate

    session = RedmineMcpServer::Session.new(response.stream, @project)
    @@sessions[session.id] = session
    Rails.logger.info("Registered SSE #{session.id}.")

    endpoint = url_for(controller: :mcp, action: :messages, only_path: true, params: {session_id: session.id})
    session.open(endpoint)

    session.wait_for_finished
  ensure
    @@sessions.delete(session.id)
    Rails.logger.info("Unregistered SSE #{session.id}.")
    session.close
  end

  def messages
    session_id = params[:session_id]
    return render(plain: 'Bad Request', status: :bad_request) unless session_id

    session = @@sessions[session_id]
    return render(plain: 'Bad Request', status: :bad_request) unless session

    req = JSON.parse(request.body.read, symbolize_names: true)
    session.handle(req)

    render(plain: 'Accepted', status: :accepted)
  rescue JSON::ParserError => e
    Rails.logger.error(e)
    render(plain: 'Bad Request', status: :bad_request)
  end
end
