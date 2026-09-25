#!/usr/bin/env python3
"""Smoke test for the Featherless OpenAI-compatible API (stdlib only).

Reads FEATHERLESS_API_KEY / FEATHERLESS_BASE_URL / FEATHERLESS_MODEL from the
environment or from a .env file in the repo root.
"""
import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

DEFAULT_BASE_URL = "https://api.featherless.ai/v1"
DEFAULT_MODEL = "Qwen/Qwen2.5-Coder-32B-Instruct"


def load_dotenv(path):
    if not path.exists():
        return
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


def request(method, url, api_key, body=None, timeout=120):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return json.loads(resp.read().decode())
    except urllib.error.HTTPError as e:
        sys.exit(f"HTTP {e.code} from {url}: {e.read().decode(errors='replace')[:500]}")
    except urllib.error.URLError as e:
        sys.exit(f"Network error calling {url}: {e.reason}")


def list_models(base_url, api_key, query):
    models = request("GET", f"{base_url}/models", api_key).get("data", [])
    ids = sorted(m.get("id", "") for m in models)
    if query:
        ids = [i for i in ids if query.lower() in i.lower()]
    for i in ids[:200]:
        print(i)
    print(f"-- {len(ids)} model(s) matched" + (" (showing first 200)" if len(ids) > 200 else ""))


def chat(base_url, api_key, model, prompt):
    body = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "max_tokens": 128,
        "temperature": 0,
    }
    started = time.time()
    resp = request("POST", f"{base_url}/chat/completions", api_key, body)
    elapsed = time.time() - started
    print(f"model:   {resp.get('model', model)}")
    print(f"latency: {elapsed:.1f}s")
    print(f"usage:   {resp.get('usage')}")
    print("reply:")
    print(resp["choices"][0]["message"]["content"])


def main():
    load_dotenv(Path(__file__).resolve().parent.parent / ".env")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--list", nargs="?", const="", metavar="QUERY",
                        help="list available models, optionally filtered by substring")
    parser.add_argument("--model", default=os.environ.get("FEATHERLESS_MODEL") or DEFAULT_MODEL)
    parser.add_argument("--prompt", default="Reply with exactly: pong")
    args = parser.parse_args()

    api_key = os.environ.get("FEATHERLESS_API_KEY")
    if not api_key:
        sys.exit("FEATHERLESS_API_KEY is not set (put it in .env or export it)")
    base_url = (os.environ.get("FEATHERLESS_BASE_URL") or DEFAULT_BASE_URL).rstrip("/")

    if args.list is not None:
        list_models(base_url, api_key, args.list)
    else:
        chat(base_url, api_key, args.model, args.prompt)


if __name__ == "__main__":
    main()
