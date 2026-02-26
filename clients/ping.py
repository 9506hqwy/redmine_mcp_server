#!/usr/bin/env python3
# /// script
# dependencies = ["mcp"]
# requires-python = ">=3.11"
# ///

import asyncio

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

            await session.send_ping()

            await asyncio.sleep(3)

            await session.send_ping()


if __name__ == "__main__":
    asyncio.run(main())
