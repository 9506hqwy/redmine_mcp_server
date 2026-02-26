#!/usr/bin/env python3
# /// script
# dependencies = ["mcp"]
# requires-python = ">=3.11"
# ///

import json

from mcp import ClientSession
from mcp.client.streamable_http import streamable_http_client


async def main():
    async with streamable_http_client("http://127.0.0.1:3000/projects/test-project/mcp") as (
        read,
        write,
        _,
    ):
        async with ClientSession(read, write) as session:
            await session.initialize()

            res = await session.list_tools()
            list_wiki_pages = (
                t for t in res.tools if t.name == "list_wiki_pages"
            ).__next__()
            read_wiki_page = (
                t for t in res.tools if t.name == "read_wiki_page"
            ).__next__()

            res = await session.call_tool(list_wiki_pages.name)
            page = json.loads(res.content[0].text)

            res = await session.call_tool(read_wiki_page.name, {"id": page["id"]})
            print(res.content[0].text)


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
