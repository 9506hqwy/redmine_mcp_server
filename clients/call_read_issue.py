#!/usr/bin/env python3
import json

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
            list_issues = (t for t in res.tools if t.name == "list_issues").__next__()
            read_issue = (t for t in res.tools if t.name == "read_issue").__next__()

            res = await session.call_tool(list_issues.name)
            issue = json.loads(res.content[0].text)

            res = await session.call_tool(read_issue.name, {"id": issue["id"]})
            print(res.content[0].text)


if __name__ == "__main__":
    import asyncio

    asyncio.run(main())
