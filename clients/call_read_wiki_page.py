#!/usr/bin/env python3
# /// script
# dependencies = ["mcp>=2"]
# requires-python = ">=3.11"
# ///

import json

from mcp import Client


async def main():
    async with Client("http://127.0.0.1:3000/projects/test-project/mcp") as client:
        res = await client.call_tool("list_wiki_pages")
        page = json.loads(res.content[0].text)

        res = await client.call_tool("read_wiki_page", {"id": page["id"]})
        print(res.content[0].text)


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
