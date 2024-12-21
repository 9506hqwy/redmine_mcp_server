# Redmine MCP Server

This plugin provides a Model Context Protocol server using Server Side Event.

## Notes

- This plugin is concept and experimental.
- HTTP endpoint does not have authenticate.
- Using WEBrick does not work (see [12.3.3 Streaming Considerations](https://guides.rubyonrails.org/v4.2/action_controller_overview.html)).
- `ActionController:Live` streaming has some problems depend on depnedencies library's version (see [Version 2.2.x breaks Rails Actioncontroller:Live streaming](https://github.com/rack/rack/issues/1619)).

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

## Exampls

see [clients](./clients) directory.

## Tested Environment

* Redmine (Docker Image)
  * 6.0
* Database
  * SQLite
  * MySQL 8.0
  * PostgreSQL 12

## References

- [Model Context Protocol](https://modelcontextprotocol.io/introduction)
