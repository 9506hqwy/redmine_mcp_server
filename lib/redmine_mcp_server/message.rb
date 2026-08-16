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
    MPC_ERR_HEADER_MISMATCH = -32020
    MCP_ERR_MISSING_REQUIRED_CLIENT_CAPABILITY = -32021
    MCP_ERR_UNSUPPORTED_PROTOCOL_VERSION = -32022
    PROTOCOL_VERSION = "2026-07-28"

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

    def self.err_unsupported_protocol_version(id, requested)
      support_versions = [PROTOCOL_VERSION]
      data = {
        supported: support_versions,
        requested: requested,
      }
      self.error(id, MCP_ERR_UNSUPPORTED_PROTOCOL_VERSION, "Unsupported protocol version", data)
    end

    def self.server_discover(id)
      result = {
        _meta: self._meta,
        resultType: "complete",
        supportedVersions: [PROTOCOL_VERSION],
        capabilities: {
          tools: {
            listChanged: false,
          },
        },
        ttlMs: 1000,
        cacheScope: "public",
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
        _meta: self._meta,
        resultType: "complete",
        nextCursor: nil,
        ttlMs: 1000,
        cacheScope: "public",
        tools: [list_issues, list_wiki_pages, read_issue, read_wiki_page],
      }

      response(id).merge!({result: result})
    end

    def self.call_tool_text_results(id, text_array)
      content = text_array.map do |text|
        { type: "text", text: text }
      end

      result = {
        _meta: self._meta,
        resultType: "complete",
        content: content,
      }

      response(id).merge!({result: result})
    end

    def self._meta
      {
        'io.modelcontextprotocol/serverInfo': {
          name: "RedmineMcpServer",
          version: "0.3.0"
        }
      }
    end
  end
end
