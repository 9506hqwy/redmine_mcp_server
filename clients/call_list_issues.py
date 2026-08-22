#!/usr/bin/env python3
# /// script
# dependencies = ["mcp>=2"]
# requires-python = ">=3.11"
# ///

import os
from mcp import Client


async def main():
    api_key = os.getenv("REDMINE_API_KEY")
    async with Client(
        f"http://127.0.0.1:3000/projects/test-project/mcp?key={api_key}"
    ) as client:
        res = await client.call_tool("list_issues")
        for page in res.content:
            print(page.text)


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
