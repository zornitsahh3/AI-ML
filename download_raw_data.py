"""
Download Chitanka works from titles_list.json.

- Book URLs (/book/...) are resolved via the reader link (a.textlink -> /text/...).
- Text is taken from div#textstart (not div#content).
- For long works, prefer .../text/<slug>/0 (full text on one page); fallback to base URL.
"""
from __future__ import annotations

import json
import re
import time
from pathlib import Path
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup

BASE = "https://chitanka.info"
MANIFEST = Path(__file__).with_name("titles_list.json")
OUT_DIR = Path(__file__).with_name("downloaded_texts")
HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/120.0.0.0 Safari/537.36"
    )
}
SLEEP_S = 1.5


def sanitize_filename(name: str) -> str:
    """Windows-safe filename (keeps Cyrillic)."""
    name = re.sub(r'[<>:"/\\|?*]', "_", name)
    name = name.strip().strip(".")
    return name or "untitled"


def resolve_text_url(session: requests.Session, page_url: str) -> str | None:
    """
    If page_url is a book page, return absolute /text/... URL from a.textlink.
    If it is already a text URL, return normalized absolute URL.
    """
    r = session.get(page_url, timeout=30, headers=HEADERS)
    r.raise_for_status()
    if not r.encoding or r.encoding.lower() == "iso-8859-1":
        r.encoding = r.apparent_encoding
    soup = BeautifulSoup(r.text, "html.parser")
    path = urlparse(page_url).path

    if "/book/" in path:
        link = soup.select_one('a.textlink[href^="/text/"]')
        if not link or not link.get("href"):
            return None
        return urljoin(BASE, link["href"])

    if "/text/" in path:
        return urljoin(BASE, path)

    return None


def _html_has_textstart(html: str) -> bool:
    soup = BeautifulSoup(html, "html.parser")
    return soup.find("div", id="textstart") is not None


def _numeric_text_url(text_url: str) -> str | None:
    m = re.search(r"/text/(\d+)(?:-[^/]+)?/?$", text_url.rstrip("/"))
    if not m:
        return None
    return urljoin(BASE, f"/text/{m.group(1)}")


def fetch_text_html(session: requests.Session, text_url: str) -> str:
    text_url = text_url.rstrip("/")
    candidates: list[str] = [f"{text_url}/0", text_url]
    alt = _numeric_text_url(text_url)
    if alt and alt not in candidates:
        candidates.extend([f"{alt}/0", alt])

    last_error: Exception | None = None
    for candidate in candidates:
        for attempt in range(3):
            try:
                r = session.get(candidate, timeout=45, headers=HEADERS)
                if r.status_code in (429, 503) or r.status_code >= 500:
                    time.sleep(2.0 * (attempt + 1))
                    continue
                if r.status_code != 200:
                    break
                if not r.encoding or r.encoding.lower() == "iso-8859-1":
                    r.encoding = r.apparent_encoding
                if _html_has_textstart(r.text):
                    return r.text
            except requests.RequestException as e:
                last_error = e
                time.sleep(2.0 * (attempt + 1))
                continue
            time.sleep(1.0 * (attempt + 1))

    if last_error:
        raise last_error
    raise RuntimeError(f"No readable text page for {text_url!r}")


def extract_body_text(html: str) -> str | None:
    soup = BeautifulSoup(html, "html.parser")
    for tag in soup(["script", "style", "noscript"]):
        tag.decompose()
    node = soup.find("div", id="textstart")
    if not node:
        return None
    return node.get_text("\n", strip=True)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    with MANIFEST.open("r", encoding="utf-8") as f:
        data = json.load(f)

    session = requests.Session()

    for author, books in data.items():
        author_dir = OUT_DIR / sanitize_filename(author)
        author_dir.mkdir(parents=True, exist_ok=True)

        for book in books:
            title = book["title"]
            url = book["url"]
            text_id = book.get("text_id", "")

            base_name = f"{text_id} - {author} - {title}"
            filename = sanitize_filename(base_name) + ".txt"
            out_path = author_dir / filename

            print("Processing:", url)

            try:
                text_page = resolve_text_url(session, url)
                if not text_page:
                    print("  Could not find /text/ link (book page layout?):", url)
                    continue

                html = fetch_text_html(session, text_page)
                text = extract_body_text(html)
                if not text:
                    print("  No div#textstart:", text_page)
                    continue

                out_path.write_text(text, encoding="utf-8")
                print("  Saved:", out_path)
            except requests.RequestException as e:
                print("  HTTP error:", e)
            except RuntimeError as e:
                print("  Skip:", e)

            time.sleep(SLEEP_S)


if __name__ == "__main__":
    main()
