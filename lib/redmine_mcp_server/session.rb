# frozen_string_literal: true

require 'json'

module RedmineMcpServer
  class Session
    include Rails.application.routes.url_helpers

    def initialize(project)
      @project = project
    end

    def handle(request, headers)
      Rails.logger.info(headers)

      metadata = request[:params][:_meta]
      protocol_version = metadata[:'io.modelcontextprotocol/protocolVersion']
      capabilities = metadata[:'io.modelcontextprotocol/clientCapabilities']
      client_info = metadata[:'io.modelcontextprotocol/clientInfo']
      Rails.logger.info(capabilities)
      Rails.logger.info(client_info)

      if headers[:protocol_version] != protocol_version
        res = Message.err_invalid_request(request[:id])
        return :bad_request, res
      end

      if headers[:method] != request[:method]
        res = Message.err_invalid_request(request[:id])
        return :bad_request, res
      end

      if protocol_version != Message::PROTOCOL_VERSION
        res = Message.err_unsupported_protocol_version(request[:id], protocol_version)
        return :bad_request, res
      end

      # TODO: verification
      case request[:method]
      when "server/discover"
        res = mcp_server_discover(request[:id])
        return :ok, res

      when "tools/list"
        res = mcp_tools_list(request[:id])
        return :ok, res

      when "tools/call"
        if headers[:name] != request[:params][:name]
          res = Message.err_invalid_request(request[:id])
          return :bad_request, res
        end

        res = mcp_tools_call(
          request[:id],
          request[:params][:name],
          request[:params][:arguments]
        )
        return :ok, res

      else
        res = Message.err_method_not_found(request[:id])
        return :not_found, res
      end
    end

    def mcp_server_discover(id)
      Message.server_discover(id)
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
