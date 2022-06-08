import asyncio
import aiohttp
from pathlib import Path
import json
import os


REQUEST_CACHE_FILE = Path(__file__).parent / "cache/request_cache.json"
if os.path.exists(REQUEST_CACHE_FILE):
    with open(REQUEST_CACHE_FILE, "r") as f:
        REQUEST_CACHE = json.load(f)
else:
    REQUEST_CACHE = {}


async def cached_get(url, **kwargs):
    if url in REQUEST_CACHE:
        return REQUEST_CACHE[url]
    async with aiohttp.ClientSession() as session:
        async with session.get(url, **kwargs) as response:
            response_text = await response.text()
            REQUEST_CACHE[url] = response_text

    with open(REQUEST_CACHE_FILE, "w+") as f:
        json.dump(REQUEST_CACHE, f)
    return response_text