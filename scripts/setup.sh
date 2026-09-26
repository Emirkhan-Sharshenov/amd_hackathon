#!/usr/bin/env bash
# Checks and installs what the hackathon needs on macOS, Linux or Windows WSL2,
# then prepares the workspace (kickoff repo, harness venv, band-work folders).
#
#   bash setup.sh            # check, install what is missing, prepare workspace
#   bash setup.sh --check    # only report what is missing, change nothing
#
# Workspace defaults to ~/hack; override with WS=/path bash setup.sh
set -euo pipefail

CHECK_ONLY=0
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=1
WS="${WS:-$HOME/hack}"
FACTORY_REPO="https://github.com/Emirkhan-Sharshenov/amd_hackathon.git"
FACTORY_BRANCH="claude/brave-knuth-9g2zoo"
KICKOFF_REPO="https://github.com/band-ai/dark-factory-wearedevs.git"

ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
miss() { printf '  \033[31m✗\033[0m %s\n' "$*"; }
step() { printf '\n\033[1m%s\033[0m\n' "$*"; }
has()  { command -v "$1" >/dev/null 2>&1; }

OS="$(uname -s)"
IS_WSL=0
grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=1

sudo_cmd() { if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi; }

# Prints a python >= 3.12 interpreter, or nothing.
find_python() {
  for p in python3.13 python3.12 python3; do
    if has "$p" && "$p" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 12) else 1)' 2>/dev/null; then
      echo "$p"; return
    fi
  done
}

step "System: $OS$([[ $IS_WSL == 1 ]] && echo ' (WSL2)')  workspace: $WS"

# ---------- check ----------
step "Checking tools"
MISSING=()
if has git; then ok "git $(git --version | awk '{print $3}')"; else miss git; MISSING+=(git); fi
PY="$(find_python)"
if [[ -n "$PY" ]]; then ok "python $($PY -V 2>&1 | awk '{print $2}') ($PY)"; else miss "python 3.12+"; MISSING+=(python); fi
if has docker; then
  ok "docker $(docker --version | awk '{print $3}' | tr -d ,)"
  if docker info >/dev/null 2>&1; then ok "docker daemon running"; else miss "docker daemon not running"; fi
else miss docker; MISSING+=(docker); fi
if [[ "$OS" == "Darwin" ]]; then
  if has brew; then ok "homebrew"; else miss homebrew; MISSING=(brew "${MISSING[@]}"); fi
fi

if [[ $CHECK_ONLY == 1 ]]; then
  step "Check only: ${#MISSING[@]} missing${MISSING:+: ${MISSING[*]}}"
  exit 0
fi

# ---------- install ----------
if (( ${#MISSING[@]} )); then
  step "Installing: ${MISSING[*]}"
  if [[ "$OS" == "Darwin" ]]; then
    if [[ " ${MISSING[*]} " == *" brew "* ]]; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
    fi
    [[ " ${MISSING[*]} " == *" git "* ]] && brew install git
    [[ " ${MISSING[*]} " == *" python "* ]] && brew install python@3.12
    if [[ " ${MISSING[*]} " == *" docker "* ]]; then
      brew install --cask docker
      echo "  → Open Docker.app once so the daemon starts, then re-run this script."
    fi
  elif has apt-get; then
    sudo_cmd apt-get update -y
    [[ " ${MISSING[*]} " == *" git "* ]] && sudo_cmd apt-get install -y git
    if [[ " ${MISSING[*]} " == *" python "* ]]; then
      if ! sudo_cmd apt-get install -y python3.12 python3.12-venv; then
        sudo_cmd apt-get install -y software-properties-common
        sudo_cmd add-apt-repository -y ppa:deadsnakes/ppa
        sudo_cmd apt-get update -y
        sudo_cmd apt-get install -y python3.12 python3.12-venv
      fi
    fi
    if [[ " ${MISSING[*]} " == *" docker "* ]]; then
      if [[ $IS_WSL == 1 ]]; then
        echo "  → On Windows install Docker Desktop and enable WSL integration:"
        echo "    https://docs.docker.com/desktop/setup/install/windows-install/"
      else
        curl -fsSL https://get.docker.com | sudo_cmd sh
        sudo_cmd usermod -aG docker "$USER" || true
        echo "  → Log out and back in so docker works without sudo."
      fi
    fi
  else
    echo "  Unsupported package manager: install ${MISSING[*]} by hand, then re-run."
    exit 1
  fi
  PY="$(find_python)"
fi

[[ -z "$PY" ]] && { echo "Python 3.12+ still missing; install it and re-run."; exit 1; }
has git || { echo "git still missing; install it and re-run."; exit 1; }

# ---------- workspace ----------
step "Preparing workspace $WS"
mkdir -p "$WS"
cd "$WS"
[[ -d dark-factory-wearedevs ]] || git clone "$KICKOFF_REPO"
[[ -d amd_hackathon ]] || git clone -b "$FACTORY_BRANCH" "$FACTORY_REPO"
ok "repositories cloned"

cd dark-factory-wearedevs
if ! "$PY" -c 'import ensurepip, venv' 2>/dev/null; then
  if has apt-get; then
    step "Installing venv support for $PY"
    sudo_cmd apt-get install -y "$(basename "$PY")-venv"
  else
    echo "Python venv/ensurepip is missing for $PY; install it and re-run."; exit 1
  fi
fi
# A half-created venv (no pip inside) is left behind when ensurepip was missing.
[[ -x .venv/bin/pip ]] || { rm -rf .venv; "$PY" -m venv .venv; }
.venv/bin/python -m pip install -q --upgrade pip
.venv/bin/python -m pip install -q -r harness/requirements.txt
if [[ "$OS" == "Linux" ]]; then
  .venv/bin/python -m playwright install --with-deps chromium
else
  .venv/bin/python -m playwright install chromium
fi
.venv/bin/python -m harness --help >/dev/null && ok "harness works"

mkdir -p ../band-work/toy-result/mandates ../band-work/checks
for f in ../amd_hackathon/mandates/*.md; do
  [[ -e ../band-work/toy-result/mandates/$(basename "$f") ]] || cp "$f" ../band-work/toy-result/mandates/
done
[[ -d ../band-work/toy-result/.git ]] || git -C ../band-work/toy-result init -q -b main
ok "band-work prepared"

step "Done. Still manual:"
docker info >/dev/null 2>&1 || echo "  • start Docker (Docker Desktop / systemctl start docker)"
echo "  • install Band Desktop and sign in"
echo "  • fill Harness:/Model: in $WS/band-work/toy-result/mandates/*.md"
echo "  • absolute path for the agents: $(cd ../band-work/toy-result && pwd)"
echo "  • then follow TOY-RUN.md from step 3"
