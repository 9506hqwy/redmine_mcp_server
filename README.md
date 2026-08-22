# Redmine MCP Server

This plugin provides a Model Context Protocol server using Streamable HTTP.

## Notes

- This plugin is concept and experimental.
- This plugin uses protocol version 2026-07-28.
- Not support Server Sent Events (`Accept: text/event-stream`).

## Features

- Tool `list_issues` is all issue listed per project.
- Tool `list_wiki_pages` is all wiki page listed per project.
- Tool `read_issue` is a issue read.
- Tool `read_wiki_page` is a wiki page read.

## Installation

1. Download plugin in Redmine plugin directory.

   ```sh
   git clone https://github.com/9506hqwy/redmine_mcp_server.git
   ```

2. Start Redmine

## Configuration

1. Enable plugin module.

   Check [MCP Server] in project setting.

2. Customize permission.

   Check [Post MCP message] in role and permission.

3. Set API Key

   Create API key and set to HTTP request using `X-Redmine-API-Key` header or `key` query parameter.

## Exampls

see [clients](./clients) directory.

## Tested Environment

- Redmine (Docker Image)
  - 5.0
  - 5.1
  - 6.0
  - 6.1
  - 7.0
- Database
  - SQLite
  - MySQL 5.7 or 8.0
  - PostgreSQL 14

## References

- [Model Context Protocol](https://modelcontextprotocol.io/introduction)
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
- [MCP Server](https://www.redmine.org/issues/42689)
