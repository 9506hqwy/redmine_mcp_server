# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class MessageTest <  ActiveSupport::TestCase
  fixtures :enabled_modules,
           :enumerations,
           :issues,
           :issue_statuses,
           :member_roles,
           :members,
           :projects,
           :projects_trackers,
           :roles,
           :users,
           :trackers,
           :versions,
           :wiki_content_versions,
           :wiki_contents,
           :wiki_pages,
           :wikis

  def test_response
    req = RedmineMcpServer::Message.response("1")
    assert_equal req, { jsonrpc: "2.0", id: "1" }
  end

  def test_err_parse
    req = RedmineMcpServer::Message.err_parse
    assert_equal req, { jsonrpc: "2.0", error: { code: -32700, message: "Parse error" } }
  end

  def test_err_invalid_request
    req = RedmineMcpServer::Message.err_invalid_request(1)
    assert_equal req, { jsonrpc: "2.0", id: 1, error: { code: -32600, message: "Invalid Request" } }
  end

  def test_err_method_not_found
    req = RedmineMcpServer::Message.err_method_not_found(2)
    assert_equal req, { jsonrpc: "2.0", id: 2, error: { code: -32601, message: "Method not found" } }
  end

  def test_err_generic
    req = RedmineMcpServer::Message.err_generic(3)
    assert_equal req, { jsonrpc: "2.0", id: 3, error: { code: 0, message: "Generic error" } }
  end

  def test_err_unsupported_protocol_version
    req = RedmineMcpServer::Message.err_unsupported_protocol_version(4, "1.0")
    assert_equal req, {
      jsonrpc: "2.0",
      id: 4,
      error: {
        code: -32022,
        message: "Unsupported protocol version",
        data: {
          supported: ["2026-07-28"],
          requested: "1.0"
        }
      }
    }
  end

  def test_server_discover
    req = RedmineMcpServer::Message.server_discover("1")
    assert_equal req, {
      jsonrpc: "2.0",
      id: "1",
      result: {
        _meta: {
          'io.modelcontextprotocol/serverInfo': {
            name: "RedmineMcpServer",
            version: "0.3.0",
          },
        },
        resultType: "complete",
        supportedVersions: ["2026-07-28"],
        capabilities: {
          tools: {
            listChanged: false,
          },
        },
        ttlMs: 1000,
        cacheScope: "public",
      }
    }
  end

  def test_tools_list
    p = Project.first

    req = RedmineMcpServer::Message.tools_list("1", p)
    assert_equal req, {
      jsonrpc: "2.0",
      id: "1",
      result: {
        _meta: {
          'io.modelcontextprotocol/serverInfo': {
            name: "RedmineMcpServer",
            version: "0.3.0",
          },
        },
        resultType: "complete",
        nextCursor: nil,
        ttlMs: 1000,
        cacheScope: "public",
        tools: [
          {
            name: "list_issues",
            description: "List all issues in project.",
            inputSchema: {
              type: "object",
            },
          },
          {
            name: "read_issue",
            description: "Read issue in project.",
            inputSchema: {
              type: "object",
              properties: {
                id: {
                  type: "integer",
                  description: "Issue's id",
                },
              },
              required: ["id"],
            },
          },
          {
            name: "list_wiki_pages",
            description: "List all wiki pages in project.",
            inputSchema: {
              type: "object",
            },
          },
          {
            name: "read_wiki_page",
            description: "Read wiki page in project.",
            inputSchema: {
              type: "object",
              properties: {
                id: {
                  type: "integer",
                  description: "Wiki's id",
                },
              },
              required: ["id"],
            },
          },
        ]
      }
    }
  end

  def test_call_tool_text_results
    req = RedmineMcpServer::Message.call_tool_text_results("1", ["result"])
    assert_equal req, {
      jsonrpc: "2.0",
      id: "1",
      result: {
        _meta: {
          'io.modelcontextprotocol/serverInfo': {
            name: "RedmineMcpServer",
            version: "0.3.0",
          },
        },
        resultType: "complete",
        content: [
          {
            type: "text",
            text: "result",
          },
        ],
      },
    }
  end
end
