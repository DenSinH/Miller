import asyncio
from bs4 import BeautifulSoup

import request

from pathlib import Path
import json
import os
import re
import time
from pprint import pprint


MILL_LINKS_CACHE = Path(__file__).parent / "cache/mill_links.json"
MILL_INFO_CACHE  = Path(__file__).parent / "cache/mill_info.json"

MAX_PAGES = 51
PAGE_LINKS_FILE = ""
BASE_URL = "https://www.molendatabase.nl/nederland"


def index_url(idx):
    return f"{BASE_URL}/molens.php?pageNum_kijkmolen={idx}&sb=&totalRows_kijkmolen=1218"


def chunks(lst, n):
    for i in range(0, len(lst), n):
        yield lst[i: i + n]


async def index_links(idx):
    page = await request.cached_get(index_url(idx))
    soup = BeautifulSoup(page, "html.parser")
    links = []
    for molennaam in soup.find_all("div", {"class": "molennaam"}):
        for link in molennaam.findChildren("a"):
            links.append(link["href"])
    return links


async def get_page_links():
    links = []
    futures = [index_links(idx) for idx in range(MAX_PAGES)]
    for _links in await asyncio.gather(*futures):
        links += _links
    return links


async def get_mill_info(url):
    page = await request.cached_get(f"{BASE_URL}/{url}")
    soup = BeautifulSoup(page, "html.parser")
    aside = soup.find("div", {"class": "aside"})
    info = {}
    image = aside.findChild("img")["src"]
    info["image"] = image
    credits = aside.findChild("span", {"class": "eerstecredits"}).text
    info["credits"] = credits
    info["meta"] = {}

    for attrib in soup.find("article").findChildren("div", {"class": "attrib"}):
        key = attrib.findChild("label")
        value = attrib.findChild("div", {"class": "textpart"})
        info["meta"][key.text] = re.sub(r"[\s\t]+", " ", value.text.strip())
        match = re.match(r"(.*)Toon op.*", info["meta"][key.text], flags=re.IGNORECASE)
        if match is not None:
            info["meta"][key.text] = match.group(1)

    info["name"] = info["meta"].pop("Naam", None)

    history = soup.find("section", {"class": "geschiedenis"})
    try:
        history_text = history.findChild("div", {"class": "textpart"}).text.strip()
        info["history"] = history_text
    except:
        info["history"] = None
    return info


async def main():
    if not os.path.exists(MILL_LINKS_CACHE):
        links = await get_page_links()
        with open(MILL_LINKS_CACHE, "w+") as f:
            json.dump(links, f)
    else:
        with open(MILL_LINKS_CACHE, "r") as f:
            links = json.load(f)

    if not os.path.exists(MILL_INFO_CACHE):
        mills = []
        for chunk in chunks(links, 10):
            for info in await asyncio.gather(*[get_mill_info(link) for link in chunk]):
                mills.append(info)
        with open(MILL_INFO_CACHE, "w+") as f:
            json.dump(mills, f, indent=2)
    else:
        with open(MILL_INFO_CACHE, "r") as f:
            mills = json.load(f)
    print(f"{len(mills)} mills loaded")


if __name__ == '__main__':
    asyncio.run(main())
