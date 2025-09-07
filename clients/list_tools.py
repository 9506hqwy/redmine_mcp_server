#!/usr/bin/env python3
# /// script
# dependencies = ["mcp"]
# requires-python = ">=3.11"
# ///

from mcp import ClientSession
from mcp.client.sse import sse_client


async def main():
    async with sse_client("http://127.0.0.1:3000/projects/test_project/mcp/sse") as (
        read,
        write,
    ):
        async with ClientSession(read, write) as session:
            await session.initialize()

            res = await session.list_tools()
            for tool in res.tools:
                print(tool)


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
