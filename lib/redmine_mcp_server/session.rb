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

    attr_reader :id

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
        pages = call_list_issues(arguments)
        response = Message.call_tool_text_results(id, pages)
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

    def call_list_issues(arguments)
      Issue.where(project: @project).map do |issue|
        JSON.dump({
                    subject: issue.subject,
                    url: object_url(issue),
                  })
      end
    end

    def object_url(obj)
      options = { protocol: Setting.protocol }
      if Setting.host_name.to_s =~ /\A(https?:\/\/)?(.+?)(:(\d+))?(\/.+)?\z/i
        host, port, path = $2, $4, $5
        options.merge!({
                         host: host,
                         port: port,
                         script_name: path,
                       })
      else
        options[:host] = Setting.host_name
      end

      url_for(obj.event_url(options))
    end
  end
end
