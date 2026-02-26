# frozen_string_literal: true

module RedmineMcpServer
  module Message
    JSONRPC_VERSION = "2.0"
    JSONRPC_ERR_PARSE = -32700
    JSONRPC_ERR_INVALID_REQUEST = -32600
    JSONRPC_ERR_METHOD_NOT_FOUND = -32601
    JSONRPC_ERR_INVALID_PARAMS = -32602
    JSONRPC_ERR_INTERNAL = -32603
    JSONRPC_ERR_GENERIC = 0
    PROTOCOL_VERSION = "2025-11-25"

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

    def self.error(id, code, message, data)
      err = {
        jsonrpc: JSONRPC_VERSION
      }

      if id
        err[:id] = id
      end

      err[:error] = {
        code: code,
        message: message
      }

      if data
        err[:error][:data] = data
      end

      err
    end

    def self.err_parse
      self.error(nil, JSONRPC_ERR_PARSE, "Parse error", nil)
    end

    def self.err_invalid_request(id)
      self.error(id, JSONRPC_ERR_INVALID_REQUEST, "Invalid Request", nil)
    end

    def self.err_method_not_found(id)
      self.error(id, JSONRPC_ERR_METHOD_NOT_FOUND, "Method not found", nil)
    end

    def self.err_generic(id)
      self.error(id, JSONRPC_ERR_GENERIC, "Generic error", nil)
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
