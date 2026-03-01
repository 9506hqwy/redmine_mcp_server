# frozen_string_literal: true

require 'json'
require 'monitor'
require 'securerandom'

module RedmineMcpServer
  class Session
    include Rails.application.routes.url_helpers

    # rubocop:disable Style/ClassVars
    @@sessions = {}
    @@sessions.extend(MonitorMixin)

    @@watcher = Thread.new do
      loop do
        sleep(1)

        @@sessions.synchronize do
          @@sessions.each_value do |s|
            s.finish if s.expired < Time.now
          end
        end
      end
    end
    # rubocop:enable Style/ClassVars

    STATE_NOT_INITIALIZE = 0
    STATE_INITIALIZING = 1
    STATE_ACCEPTABLE = 2
    STATE_CLOSED = 3

    attr_reader :id, :status, :expired

    def self.get(id)
      s = nil

      @@sessions.synchronize do
        s = @@sessions[id]
        s.extend_expire_time if s
      end

      s
    end

    def initialize(project, timeout)
      super()
      @id = SecureRandom.uuid
      @project = project

      @timeout = timeout
      @expired = expire_time(@timeout)

      @status = STATE_NOT_INITIALIZE

      @@sessions.synchronize do
        @@sessions[@id] = self
      end

      Rails.logger.info("Registered Session #{@id}.")
    end

    def finish
      @status = STATE_CLOSED

      @@sessions.synchronize do
        @@sessions.delete(@id)
      end

      Rails.logger.info("Unregistered Session #{@id} (#{@expired}).")
    end

    def extend_expire_time
      @expired = expire_time(@timeout)
      Rails.logger.info("Extended Session #{@id} (#{@expired}).")
    end

    def expire_time(sec)
      Time.now + sec
    end

    def close
      finish
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
        Message.err_method_not_found(request[:id])
      end
    end

    def mcp_initialize(id, protocol_version, capabilities, client_info)
      @status = STATE_INITIALIZING

      Rails.logger.info(capabilities)
      Rails.logger.info(client_info)

      Message.initialize_result(id, protocol_version)
    end

    def mcp_initialized
      @status = STATE_ACCEPTABLE
      return
    end

    def mcp_pong(id)
      Message.pong(id)
    end

    def mcp_tools_list(id)
      Message.tools_list(id)
    end

    def mcp_tools_call(id, name, arguments)
      case name
      when "list_issues"
        issues = call_list_issues
        Message.call_tool_text_results(id, issues)
      when "list_wiki_pages"
        pages = list_wiki_pages
        Message.call_tool_text_results(id, pages)
      when "read_issue"
        issue = call_read_issue(arguments[:id])
        Message.call_tool_text_results(id, [issue])
      when "read_wiki_page"
        page = call_read_wiki_page(arguments[:id])
        Message.call_tool_text_results(id, [page])
      end
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
