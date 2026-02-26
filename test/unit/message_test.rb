# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class MessageTest <  ActiveSupport::TestCase
  def test_request
    req = RedmineMcpServer::Message.request("method")
    assert_equal req, { jsonrpc: "2.0", method: "method" }
  end

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

  def test_ping
    req = RedmineMcpServer::Message.ping("1")
    assert_equal req, { jsonrpc: "2.0", method: "ping", id: "1" }
  end

  def test_pong
    req = RedmineMcpServer::Message.pong("1")
    assert_equal req, { jsonrpc: "2.0", id: "1", result: {} }
  end

  def test_initialize_result
    req = RedmineMcpServer::Message.initialize_result("1", "1.0")
    assert_equal req, {
      jsonrpc: "2.0",
      id: "1",
      result: {
        protocolVersion: "1.0",
        capabilities: {
          tools: {
            listChanged: false,
          },
        },
        serverInfo: {
          name: "RedmineMcpServer",
          version: "0.1.0",
        }
      }
    }
  end

  def test_tools_list
    req = RedmineMcpServer::Message.tools_list("1")
    assert_equal req, {
      jsonrpc: "2.0",
      id: "1",
      result: {
        tools: [
          {
            name: "list_issues",
            description: "List all issues in project.",
            inputSchema: {
              type: "object",
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
        ],
        nextCursor: nil,
      }
    }
  end

  def test_call_tool_text_results
    req = RedmineMcpServer::Message.call_tool_text_results("1", ["result"])
    assert_equal req, {
      jsonrpc: "2.0",
      id: "1",
      result: {
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
