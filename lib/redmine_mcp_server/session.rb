# frozen_string_literal: true

require 'json'
require 'monitor'
require 'securerandom'

module RedmineMcpServer
  class Session
    include MonitorMixin
    include Rails.application.routes.url_helpers

    STATE_NOT_INITIALIZE = 0
    STATE_INITIALIZING = 1
    STATE_ACCEPTABLE = 2
    STATE_CLOSED = 3

    attr_reader :id, :status

    def initialize(stream, project)
      super()
      @id = SecureRandom.uuid
      @sse = ActionController::Live::SSE.new(stream, event: "message")
      @project = project

      @cv = new_cond

      @status = STATE_NOT_INITIALIZE

      @iniializing = Thread.new do
        # call `finish` after few seconds without initializing.
        sleep(5)
        if @status < STATE_ACCEPTABLE
          finish
        end
      end

      @pinger = Thread.new do
        # check TCP connection periodically.
        while @status < STATE_CLOSED
          sleep(15)
          if @status == STATE_ACCEPTABLE
            mcp_ping
          end
        end
      end
    end

    def open(endpoint)
      @sse.write(endpoint, event: "endpoint")
    end

    def close
      @sse.close
      @iniializing.kill
      @pinger.kill
    end

    def wait_for_finished
      synchronize do
        @cv.wait
      end
    end

    def finish
      synchronize do
        @status = STATE_CLOSED
        @cv.broadcast
      end
    end

    def handle(request)
      # TODO: verification
      case request[:method]
      when "initialize"
        mcp_initialize(request[:id], request[:params][:protocolVersion], request[:params][:capabilities], request[:params][:clientInfo])
      when "notifications/initialized"
        mcp_initialized
      when "ping"
        mcp_pong(request[:id])
      when "tools/list"
        mcp_tools_list(request[:id])
      when "tools/call"
        mcp_tools_call(request[:id], request[:params][:name], request[:params][:arguments])
      else
        write_json(request)
      end
    end

    def mcp_initialize(id, protocol_version, capabilities, client_info)
      @status = STATE_INITIALIZING

      Rails.logger.info(capabilities)
      Rails.logger.info(client_info)

      response = Message.initialize_result(id, protocol_version)
      write_json(response)
    end

    def mcp_initialized
      @status = STATE_ACCEPTABLE
    end

    def mcp_ping
      json = Message.ping(SecureRandom.uuid)
      write_json(json)
    end

    def mcp_pong(id)
      response = Message.pong(id)
      write_json(response)
    end

    def mcp_tools_list(id)
      json = Message.tools_list(id)
      write_json(json)
    end

    def mcp_tools_call(id, name, arguments)
      case name
      when "list_issues"
        issues = call_list_issues
        response = Message.call_tool_text_results(id, issues)
        write_json(response)
      when "list_wiki_pages"
        pages = list_wiki_pages
        response = Message.call_tool_text_results(id, pages)
        write_json(response)
      when "read_issue"
        issue = call_read_issue(arguments[:id])
        response = Message.call_tool_text_results(id, [issue])
        write_json(response)
      when "read_wiki_page"
        page = call_read_wiki_page(arguments[:id])
        response = Message.call_tool_text_results(id, [page])
        write_json(response)
      end
    end

    def write_json(json)
      write_plain(json.to_json)
    end

    def write_plain(data)
      @sse.write(data)
    rescue ActionController::Live::ClientDisconnected
      finish
    end

    def call_list_issues
      Issue.where(project: @project).map do |issue|
        JSON.dump({
                    id: issue.id,
                    subject: issue.subject,
                    url: object_url(issue),
                  })
      end
    end

    def list_wiki_pages
      WikiPage.joins(:wiki).where(wikis: {project_id: @project.id}).map do |page|
        JSON.dump(
          {
            id: page.id,
            title: page.title,
            url: object_url(page),
          }
        )
      end
    end

    def call_read_issue(id)
      issue = Issue.where(id: id, project: @project).first
      JSON.dump(
        {
          id: issue.id,
          tracker: issue.tracker.name,
          subject: issue.subject,
          description: issue.description,
          due_date: issue.due_date,
          category: issue.category,
          status: issue.status.name,
          assigned_to: issue.assigned_to&.name,
        }
      )
    end

    def call_read_wiki_page(id)
      page = WikiPage.joins(:wiki).where(id: id, wikis: {project_id: @project.id}).first
      content = WikiContent.where(page: page).first
      JSON.dump(
        {
          id: page.id,
          title: page.title,
          author: content.author&.name,
          text: content.text,
          version: content.version,
        }
      )
    end

    def object_url(obj)
      options = { protocol: Setting.protocol }
      if Setting.host_name.to_s =~ /\A(https?:\/\/)?(.+?)(:(\d+))?(\/.+)?\z/i
        host, port, path = $2, $4, $5
        options.merge!({host: host, port: port, script_name: path})
      else
        options[:host] = Setting.host_name
      end

      url_for(obj.event_url(options))
    end
  end
end
