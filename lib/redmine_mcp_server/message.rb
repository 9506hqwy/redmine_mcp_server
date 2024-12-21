# frozen_string_literal: true

module RedmineMcpServer
  module Message
    JSONRPC_VERSION = "2.0"
    PROTOCOL_VERSION = "2024-11-05"

    def self.request(method)
      {
        jsonrpc: JSONRPC_VERSION,
        method: method,
      }
    end

    def self.response(id)
      {
        jsonrpc: JSONRPC_VERSION,
        id: id,
      }
    end

    def self.ping(id)
      request("ping").merge!({id: id})
    end

    def self.pong(id)
      response(id).merge!({result: {}})
    end

    def self.initialize_result(id, protocol_version)
      result = {
        protocolVersion: protocol_version,
        capabilities: {
          tools: {
            listChanged: false,
          }
        },
        serverInfo: {
          name: "RedmineMcpServer",
          version: "0.1.0"
        }
      }

      response(id).merge!({result: result})
    end

    def self.tools_list(id)
      list_issues = {
        name: "list_issues",
        description: "List all issues in project.",
        inputSchema: {
          type: "object",
        }
      }

      list_wiki_pages = {
        name: "list_wiki_pages",
        description: "List all wiki pages in project.",
        inputSchema: {
          type: "object",
        }
      }

      read_issue = {
        name: "read_issue",
        description: "Read issue in project.",
        inputSchema: {
          type: "object",
          properties: {
            id: {
              type: "integer",
              description: "Issue's id",
            }
          },
          required: ["id"]
        }
      }

      read_wiki_page = {
        name: "read_wiki_page",
        description: "Read wiki page in project.",
        inputSchema: {
          type: "object",
          properties: {
            id: {
              type: "integer",
              description: "Wiki's id",
            }
          },
          required: ["id"]
        }
      }

      result = {
        tools: [list_issues, list_wiki_pages, read_issue, read_wiki_page],
        nextCursor: nil,
      }

      response(id).merge!({result: result})
    end

    def self.call_tool_text_results(id, text_array)
      content = text_array.map do |text|
        { type: "text", text: text }
      end

      result = {
        content: content
      }

      response(id).merge!({result: result})
    end
  end
end
