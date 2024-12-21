# Redmine MCP Server

This plugin provides a Model Context Protocol server using Server Side Event.

## Notes

- This plugin is concept and experimental.
- HTTP endpoint does not have authenticate.

## Features

- Tool `list_issues` is all issue listed per project.
- Tool `list_wiki_pages` is all wiki page listed per project.
- Tool `read_issue` is a issue read.
- Tool `read_wiki_page` is a wiki page read.

## Exampls

see [./clients] directory.

## Tested Environment

* Redmine (Docker Image)
  * 6.0
* Database
  * SQLite
  * MySQL 8.0
  * PostgreSQL 12

## References

- [Model Context Protocol](https://modelcontextprotocol.io/introduction)
