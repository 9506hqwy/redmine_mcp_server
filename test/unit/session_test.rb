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

  def test_initialize_close
    w = StringIO.new
    p = Project.first
    s = RedmineMcpServer::Session.new(w, p)

    assert_not_nil s.id
    assert_equal s.status, RedmineMcpServer::Session::STATE_NOT_INITIALIZE
  ensure
    s.close
  end

  def test_initialize_timedout
    w = StringIO.new
    p = Project.first
    s = RedmineMcpServer::Session.new(w, p)

    s.wait_for_finished

    assert_equal s.status, RedmineMcpServer::Session::STATE_CLOSED
  ensure
    s.close
  end

  def test_handle_initialize
    w = StringIO.new
    p = Project.first
    s = RedmineMcpServer::Session.new(w, p)

    s.handle(initialize_request)

    assert_equal s.status, RedmineMcpServer::Session::STATE_INITIALIZING

    w.rewind
    assert_equal "event: message", w.readline(chomp: true)

    res = JSON.parse(w.readline.gsub(/^data: /, ""), symbolize_names: true)
    assert_equal res, {
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
  ensure
    s.close
  end

  def test_handle_initialized
    w = StringIO.new
    p = Project.first
    s = RedmineMcpServer::Session.new(w, p)

    s.handle(initialize_request)
    w.string = (+"")
    w.rewind

    s.handle({jsonrpc: "2.0", method: "notifications/initialized"})

    assert_equal s.status, RedmineMcpServer::Session::STATE_ACCEPTABLE
    assert_equal 0, w.tell
  ensure
    s.close
  end

  def test_handle_pong
    w = StringIO.new
    p = Project.first
    s = RedmineMcpServer::Session.new(w, p)

    s.handle(initialize_request)
    w.string = (+"")
    w.rewind

    s.handle(RedmineMcpServer::Message.ping("1"))

    w.rewind
    assert_equal "event: message", w.readline(chomp: true)

    res = JSON.parse(w.readline.gsub(/^data: /, ""), symbolize_names: true)
    assert_equal res, {
      jsonrpc: "2.0",
      id: "1",
      result: {},
    }
  ensure
    s.close
  end

  def test_handle_tools_list
    w = StringIO.new
    p = Project.first
    s = RedmineMcpServer::Session.new(w, p)

    s.handle(initialize_request)
    w.string = (+"")
    w.rewind

    s.handle(tools_list_request)

    w.rewind
    assert_equal "event: message", w.readline(chomp: true)

    res = JSON.parse(w.readline.gsub(/^data: /, ""), symbolize_names: true)
    assert_equal res, RedmineMcpServer::Message.tools_list("2")
  ensure
    s.close
  end

  def test_handle_tools_call
    w = StringIO.new
    p = Project.first
    s = RedmineMcpServer::Session.new(w, p)

    s.handle(initialize_request)
    w.string = (+"")
    w.rewind

    s.handle(tools_call_request)

    w.rewind
    assert_equal "event: message", w.readline(chomp: true)

    res = JSON.parse(w.readline.gsub(/^data: /, ""), symbolize_names: true)
    assert_not_nil res
  ensure
    s.close
  end

  def test_mcp_tools_call_list_issues
    w = StringIO.new
    p = Project.first
    s = RedmineMcpServer::Session.new(w, p)

    s.handle(tools_call_request)

    w.rewind
    assert_equal "event: message", w.readline(chomp: true)

    res = JSON.parse(w.readline.gsub(/^data: /, ""), symbolize_names: true)
    assert_not_nil res
  ensure
    s.close
  end

  def test_mcp_tools_call_list_wiki_pages
    w = StringIO.new
    p = Project.first
    s = RedmineMcpServer::Session.new(w, p)

    s.handle(list_wiki_pages_request)

    w.rewind
    assert_equal "event: message", w.readline(chomp: true)

    res = JSON.parse(w.readline.gsub(/^data: /, ""), symbolize_names: true)
    assert_not_nil res
  ensure
    s.close
  end

  def test_mcp_tools_call_read_issue
    w = StringIO.new
    p = Project.first
    s = RedmineMcpServer::Session.new(w, p)

    s.handle(read_issue_request)

    w.rewind
    assert_equal "event: message", w.readline(chomp: true)

    res = JSON.parse(w.readline.gsub(/^data: /, ""), symbolize_names: true)
    assert_not_nil res
  ensure
    s.close
  end

  def test_mcp_tools_call_read_wiki_page
    w = StringIO.new
    p = Project.first
    s = RedmineMcpServer::Session.new(w, p)

    s.handle(read_wiki_page_request)

    w.rewind
    assert_equal "event: message", w.readline(chomp: true)

    res = JSON.parse(w.readline.gsub(/^data: /, ""), symbolize_names: true)
    assert_not_nil res
  ensure
    s.close
  end

  def initialize_request
    RedmineMcpServer::Message.request("initialize").merge!(
      {
        id: "1",
        params: {
          protocolVersion: "1.0",
          capabilities: {},
          clientInfo: {},
        },
      }
    )
  end

  def tools_list_request
    RedmineMcpServer::Message.request("tools/list").merge!(
      {
        id: "2",
        params: {},
      }
    )
  end

  def tools_call_request
    RedmineMcpServer::Message.request("tools/call").merge!(
      {
        id: "3",
        params: {
          name: "list_issues",
        },
      }
    )
  end

  def list_wiki_pages_request
    RedmineMcpServer::Message.request("tools/call").merge!(
      {
        id: "3",
        params: {
          name: "list_wiki_pages",
        },
      }
    )
  end

  def read_issue_request
    RedmineMcpServer::Message.request("tools/call").merge!(
      {
        id: "3",
        params: {
          name: "read_issue",
          arguments: {
            id: 1
          }
        },
      }
    )
  end

  def read_wiki_page_request
    RedmineMcpServer::Message.request("tools/call").merge!(
      {
        id: "3",
        params: {
          name: "read_wiki_page",
          arguments: {
            id: 1
          }
        },
      }
    )
  end
end
