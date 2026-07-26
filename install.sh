#!/usr/bin/env bash
# Modular installer for agent-ding.
# Usage:
#   ./install.sh                 # notify + layouts (default)
#   ./install.sh --all
#   ./install.sh --only notify
#   ./install.sh --only layouts
#   ./install.sh --only shell
#   ./install.sh --only ghostty
#   ./install.sh --with-hooks    # merge Claude/Grok hook fragments
#   ./install.sh --with-zellij-attention
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="${BIN_DIR:-$PREFIX/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/agent-ding"
ZELLIJ_LAYOUT_DIR="${ZELLIJ_LAYOUT_DIR:-$HOME/.config/zellij/layouts}"
ZELLIJ_PLUGIN_DIR="${ZELLIJ_PLUGIN_DIR:-$HOME/.config/zellij/plugins}"

ONLY=""
WITH_HOOKS=0
WITH_ZA=0
DO_NOTIFY=0
DO_LAYOUTS=0
DO_SHELL=0
DO_GHOSTTY=0

usage() {
  sed -n '2,12p' "$0" | sed 's/^# \?//'
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage ;;
    --all) DO_NOTIFY=1; DO_LAYOUTS=1; DO_SHELL=1; DO_GHOSTTY=1; shift ;;
    --only) ONLY="${2:-}"; shift 2 ;;
    --with-hooks) WITH_HOOKS=1; shift ;;
    --with-zellij-attention) WITH_ZA=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ -n "$ONLY" ]; then
  case "$ONLY" in
    notify) DO_NOTIFY=1 ;;
    layouts) DO_LAYOUTS=1 ;;
    shell) DO_SHELL=1 ;;
    ghostty) DO_GHOSTTY=1 ;;
    *) echo "unknown package: $ONLY (notify|layouts|shell|ghostty)" >&2; exit 2 ;;
  esac
elif [ "$DO_NOTIFY$DO_LAYOUTS$DO_SHELL$DO_GHOSTTY" = "0000" ]; then
  # default: notify + layouts
  DO_NOTIFY=1
  DO_LAYOUTS=1
fi

log() { printf '→ %s\n' "$*"; }

if [ "$DO_NOTIFY" = 1 ]; then
  log "install notify → $BIN_DIR"
  mkdir -p "$BIN_DIR" "$DATA_DIR"
  install -m 755 "$ROOT/packages/notify/bin/agent-ding" "$BIN_DIR/agent-ding"
  install -m 755 "$ROOT/packages/notify/bin/agent-ding-icons" "$BIN_DIR/agent-ding-icons"
  install -m 755 "$ROOT/packages/notify/bin/agent-ding-build-apps" "$BIN_DIR/agent-ding-build-apps"

  if [[ "$(uname -s)" == "Darwin" ]]; then
    if ! command -v terminal-notifier >/dev/null 2>&1 && [ ! -d /opt/homebrew/Cellar/terminal-notifier ]; then
      log "tip: brew install terminal-notifier"
    fi
    log "build branded icons + apps (macOS)"
    "$BIN_DIR/agent-ding-icons" || log "warn: icon download failed (network?)"
    "$BIN_DIR/agent-ding-build-apps" || log "warn: app build failed"
  else
    log "non-macOS: using notify-send / fallback (no brand .app)"
  fi
fi

if [ "$DO_LAYOUTS" = 1 ]; then
  log "install layouts → $ZELLIJ_LAYOUT_DIR"
  mkdir -p "$ZELLIJ_LAYOUT_DIR"
  for f in ai-workspace.kdl groks-workspace.kdl default.kdl; do
    [ -f "$ROOT/packages/layouts/$f" ] && install -m 644 "$ROOT/packages/layouts/$f" "$ZELLIJ_LAYOUT_DIR/$f"
  done
  log "optional zellij snippet: packages/layouts/zellij-config.snippet.kdl"
fi

if [ "$DO_SHELL" = 1 ]; then
  log "shell helpers live in packages/shell/ — add to your rc:"
  echo "    source $ROOT/packages/shell/ai.zsh   # or ai.bash"
fi

if [ "$DO_GHOSTTY" = 1 ]; then
  log "ghostty snippet: packages/ghostty/config.snippet"
  GHOSTTY_CFG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    mkdir -p "$(dirname "$GHOSTTY_CFG")"
    if [ ! -f "$GHOSTTY_CFG" ] || ! grep -q 'agent-ding recommended' "$GHOSTTY_CFG" 2>/dev/null; then
      {
        echo ""
        cat "$ROOT/packages/ghostty/config.snippet"
      } >> "$GHOSTTY_CFG"
      log "appended ghostty snippet → $GHOSTTY_CFG"
    else
      log "ghostty already has agent-ding snippet"
    fi
  fi
fi

if [ "$WITH_ZA" = 1 ]; then
  log "install zellij-attention plugin"
  mkdir -p "$ZELLIJ_PLUGIN_DIR"
  curl -fsSL -L -o "$ZELLIJ_PLUGIN_DIR/zellij-attention.wasm" \
    "https://github.com/KiryuuLight/zellij-attention/releases/latest/download/zellij-attention.wasm"
  log "add load_plugins entry from packages/layouts/zellij-config.snippet.kdl"
fi

if [ "$WITH_HOOKS" = 1 ]; then
  log "hook fragments (manual merge recommended):"
  echo "  Claude: $ROOT/hooks/claude.settings.fragment.json → ~/.claude/settings.json"
  echo "  Grok:   $ROOT/hooks/grok.config.fragment.toml → ~/.grok/config.toml"
  if command -v python3 >/dev/null 2>&1 && [ -f "$HOME/.claude/settings.json" ]; then
    python3 - "$ROOT" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
p = Path.home() / ".claude/settings.json"
data = json.loads(p.read_text())
hooks = data.setdefault("hooks", {})
# keep PreToolUse etc., set Stop to agent-ding only for ding
ding = "agent-ding claude"
# remove previous agent-ding / hellolib stop entries then add
new_stop = []
for e in hooks.get("Stop", []):
    cmds = " ".join(h.get("command","") for h in e.get("hooks",[]))
    if "agent-ding" in cmds or "handle-claude-hook" in cmds or "notify.sh" in cmds:
        continue
    new_stop.append(e)
new_stop.append({"hooks":[{"type":"command","command": ding}]})
hooks["Stop"] = new_stop
data["hooks"] = hooks
p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
print("merged Claude Stop → agent-ding claude")
PY
  fi
fi

log "done."
echo ""
echo "Quick test:  agent-ding claude"
echo "Workspaces:  ai   |   groks   (after sourcing shell helpers + layouts)"
echo "Docs:        $ROOT/README.md"
