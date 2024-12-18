#!/usr/bin/env python3
from mcp import ClientSession
from mcp.client.sse import sse_client


async def main():
    async with sse_client("http://127.0.0.1:3000/projects/test_project/event/sse") as (
        read,
        write,
    ):
        async with ClientSession(read, write) as session:
            await session.initialize()

            res = await session.list_tools()
            list_issues = (t for t in res.tools if t.name == "list_issues").__next__()

            res = await session.call_tool(list_issues.name)
            for page in res.content:
                print(page.text)


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
