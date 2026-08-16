#!/usr/bin/env python3
# /// script
# dependencies = ["mcp>=2"]
# requires-python = ">=3.11"
# ///

from mcp import Client


async def main():
    async with Client("http://127.0.0.1:3000/projects/test-project/mcp") as client:
        print(client.protocol_version)


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
