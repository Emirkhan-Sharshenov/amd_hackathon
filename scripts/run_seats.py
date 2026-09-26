#!/usr/bin/env python3
"""Run the factory's seats as Band agents on OpenCode + Featherless.

Each seat's standing instructions are its mandate file; the model comes from the
mandate's `Model:` line, so the mandate and what actually runs cannot drift apart.

Prerequisites (see SETUP-FEATHERLESS.md):
  * `opencode serve --hostname=127.0.0.1 --port=4096` running, with the
    `featherless` provider in ~/.config/opencode/opencode.json
  * agent credentials in a YAML file kept OUTSIDE the result repository:
        coordinator: {agent_id: "...", api_key: "..."}
        builder:     {agent_id: "...", api_key: "..."}
        ...

Usage:
  python run_seats.py --repo /home/me/hack/band-work/toy-result \
      --config ~/hack/agent_config.yaml [--seats coordinator builder tester reviewer]
"""
import argparse
import asyncio
import re
import sys
from pathlib import Path

from band import Agent, Emit
from band.adapters import OpencodeAdapter, OpencodeAdapterConfig
from band.config import load_agent_config

DEFAULT_SEATS = ["coordinator", "builder", "tester", "reviewer"]


def model_from_mandate(text, seat):
    match = re.search(r"(?im)^\s*Model\s*:\s*(\S+)", text)
    if not match or match.group(1).upper().startswith("TODO"):
        sys.exit(f"mandates/{seat}.md has no real `Model:` line")
    return match.group(1)


def build_agent(seat, args):
    mandate = (args.mandates / f"{seat}.md").read_text()
    model = model_from_mandate(mandate, seat)
    agent_id, api_key = load_agent_config(seat, config_path=args.config)
    adapter = OpencodeAdapter(
        config=OpencodeAdapterConfig(
            base_url=args.opencode_url,
            directory=str(args.repo),
            provider_id="featherless",
            model_id=model,
            custom_section=mandate,
            # The seats run unattended: tool calls must not wait for a human.
            approval_mode="auto_accept",
            question_mode="auto_reject",
            turn_timeout_s=args.turn_timeout,
            session_title_prefix=seat,
        ),
        emit={Emit.TOOL_CALLS, Emit.TASK_EVENTS},
    )
    print(f"  {seat:<12} model={model}")
    return Agent.create(adapter=adapter, agent_id=agent_id, api_key=api_key)


async def main():
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--repo", required=True, type=Path,
                        help="absolute path of the result repository the seats work in")
    parser.add_argument("--mandates", type=Path,
                        help="folder with <seat>.md mandates (default: <repo>/mandates)")
    parser.add_argument("--config", required=True, type=Path,
                        help="YAML with agent_id/api_key per seat, outside the repo")
    parser.add_argument("--seats", nargs="+", default=DEFAULT_SEATS)
    parser.add_argument("--opencode-url", default="http://127.0.0.1:4096")
    parser.add_argument("--turn-timeout", type=float, default=900)
    args = parser.parse_args()

    args.repo = args.repo.expanduser().resolve()
    args.config = args.config.expanduser().resolve()
    args.mandates = (args.mandates or args.repo / "mandates").expanduser().resolve()
    if not args.repo.is_dir():
        sys.exit(f"result repository not found: {args.repo}")
    if args.config.is_relative_to(args.repo):
        sys.exit("keep the credentials file outside the result repository")

    print(f"repo: {args.repo}")
    agents = [build_agent(seat, args) for seat in args.seats]
    print("starting seats; Ctrl+C to stop")
    await asyncio.gather(*(agent.run() for agent in agents))


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        pass
