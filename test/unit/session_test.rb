# frozen_string_literal: true

require "stringio"
require "json"

require File.expand_path('../../test_helper', __FILE__)

class SessionTest <  ActiveSupport::TestCase
  fixtures :enumerations,
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

  def test_handle_server_discover
    p = Project.first
    s = RedmineMcpServer::Session.new(p)

    status, data = s.handle(server_discover_request, _headers("server/discover", nil))

    assert_equal status, :ok
    assert_equal data, RedmineMcpServer::Message.server_discover("1")
  end

  def test_handle_tools_list
    p = Project.first
    s = RedmineMcpServer::Session.new(p)

    status, data = s.handle(tools_list_request, _headers("tools/list", nil))

    assert_equal status, :ok
    assert_equal data, RedmineMcpServer::Message.tools_list("2", p)
  end

  def test_handle_tools_call
    p = Project.first
    s = RedmineMcpServer::Session.new(p)

    status, data = s.handle(tools_call_request, _headers("tools/call", "list_issues"))

    assert_equal status, :ok
    assert_not_nil data
  end

  def test_mcp_tools_call_list_issues
    p = Project.first
    s = RedmineMcpServer::Session.new(p)

    status, data = s.handle(tools_call_request, _headers("tools/call", "list_issues"))

    assert_equal status, :ok
    assert_not_nil data
  end

  def test_mcp_tools_call_list_wiki_pages
    p = Project.first
    s = RedmineMcpServer::Session.new(p)

    status, data = s.handle(list_wiki_pages_request, _headers("tools/call", "list_wiki_pages"))

    assert_equal status, :ok
    assert_not_nil data
  end

  def test_mcp_tools_call_read_issue
    p = Project.first
    s = RedmineMcpServer::Session.new(p)

    status, data = s.handle(read_issue_request, _headers("tools/call", "read_issue"))

    assert_equal status, :ok
    assert_not_nil data
  end

  def test_mcp_tools_call_read_wiki_page
    p = Project.first
    s = RedmineMcpServer::Session.new(p)

    status, data = s.handle(read_wiki_page_request, _headers("tools/call", "read_wiki_page"))

    assert_equal status, :ok
    assert_not_nil data
  end

  def server_discover_request
    _request("server/discover").merge!(
      {
        id: "1",
        params: {
          _meta: _meta,
        },
      }
    )
  end

  def tools_list_request
    _request("tools/list").merge!(
      {
        id: "2",
        params: {
          _meta: _meta,
        },
      }
    )
  end

  def tools_call_request
    _request("tools/call").merge!(
      {
        id: "3",
        params: {
          _meta: _meta,
          name: "list_issues",
        },
      }
    )
  end

  def list_wiki_pages_request
    _request("tools/call").merge!(
      {
        id: "3",
        params: {
          _meta: _meta,
          name: "list_wiki_pages",
        },
      }
    )
  end

  def read_issue_request
    _request("tools/call").merge!(
      {
        id: "3",
        params: {
          _meta: _meta,
          name: "read_issue",
          arguments: {
            id: 1
          }
        },
      }
    )
  end

  def read_wiki_page_request
    _request("tools/call").merge!(
      {
        id: "3",
        params: {
          _meta: _meta,
          name: "read_wiki_page",
          arguments: {
            id: 1
          }
        },
      }
    )
  end

  def _request(method)
    {
      jsonrpc: RedmineMcpServer::Message::JSONRPC_VERSION,
      method: method,
    }
  end

  def _headers(method, name)
    {
      protocol_version: RedmineMcpServer::Message::PROTOCOL_VERSION,
      method: method,
      name: name
    }
  end

  def _meta
    {
      'io.modelcontextprotocol/protocolVersion': RedmineMcpServer::Message::PROTOCOL_VERSION,
      'io.modelcontextprotocol/clientCapabilities': {},
    }
  end
end
