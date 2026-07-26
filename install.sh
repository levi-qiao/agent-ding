#!/usr/bin/env bash
# Modular installer for agent-ding. Records state for clean uninstall.
#
#   ./install.sh                    # notify + layouts
#   ./install.sh --all
#   ./install.sh --only notify
#   ./install.sh --only layouts
#   ./install.sh --only shell
#   ./install.sh --only ghostty
#   ./install.sh --with-hooks
#   ./install.sh --with-zellij-attention
#   ./install.sh --yes              # non-interactive tips only
#
# Prefer ./setup.sh for an owner interview.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/state.sh
source "$ROOT/lib/state.sh"

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="${BIN_DIR:-$PREFIX/bin}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/agent-ding"
ZELLIJ_LAYOUT_DIR="${ZELLIJ_LAYOUT_DIR:-$HOME/.config/zellij/layouts}"
ZELLIJ_PLUGIN_DIR="${ZELLIJ_PLUGIN_DIR:-$HOME/.config/zellij/plugins}"
SHELL_MARKER="# >>> agent-ding shell >>>"

ONLY=""
WITH_HOOKS=0
WITH_ZA=0
DO_NOTIFY=0
DO_LAYOUTS=0
DO_SHELL=0
DO_GHOSTTY=0

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \?//'
  exit 0
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage ;;
    --all) DO_NOTIFY=1; DO_LAYOUTS=1; DO_SHELL=1; DO_GHOSTTY=1; shift ;;
    --only)
      case "${2:-}" in
        notify) DO_NOTIFY=1 ;;
        layouts) DO_LAYOUTS=1 ;;
        shell) DO_SHELL=1 ;;
        ghostty) DO_GHOSTTY=1 ;;
        *) echo "unknown package: ${2:-}" >&2; exit 2 ;;
      esac
      shift 2
      ;;
    --with-hooks) WITH_HOOKS=1; shift ;;
    --with-zellij-attention) WITH_ZA=1; shift ;;
    --yes) shift ;; # reserved for CI
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ "$DO_NOTIFY$DO_LAYOUTS$DO_SHELL$DO_GHOSTTY" = "0000" ]; then
  DO_NOTIFY=1
  DO_LAYOUTS=1
fi

log() { printf '→ %s\n' "$*"; }
state_init

if [ "$DO_NOTIFY" = 1 ]; then
  log "install notify → $BIN_DIR"
  mkdir -p "$BIN_DIR" "$DATA_DIR"
  for b in agent-ding agent-ding-icons agent-ding-build-apps; do
    install -m 755 "$ROOT/packages/notify/bin/$b" "$BIN_DIR/$b"
    state_add bins "$BIN_DIR/$b"
  done
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if [ ! -d /opt/homebrew/Cellar/terminal-notifier ] && ! command -v terminal-notifier >/dev/null 2>&1; then
      if command -v brew >/dev/null 2>&1; then
        log "brew install terminal-notifier"
        brew install terminal-notifier || log "warn: brew install failed"
      else
        log "warn: install terminal-notifier for branded icons"
      fi
    fi
    log "build brand icons + apps"
    "$BIN_DIR/agent-ding-icons" || log "warn: icons failed (network?)"
    "$BIN_DIR/agent-ding-build-apps" || log "warn: app build failed"
    state_add markers "data_dir:$DATA_DIR"
  fi
fi

if [ "$DO_LAYOUTS" = 1 ]; then
  log "install layouts → $ZELLIJ_LAYOUT_DIR"
  mkdir -p "$ZELLIJ_LAYOUT_DIR"
  for f in ai-workspace.kdl groks-workspace.kdl default.kdl; do
    src="$ROOT/packages/layouts/$f"
    dst="$ZELLIJ_LAYOUT_DIR/$f"
    [ -f "$src" ] || continue
    install -m 644 "$src" "$dst"
    state_add layouts "$dst"
  done
  install -m 644 "$ROOT/packages/layouts/DIY.md" "$ZELLIJ_LAYOUT_DIR/agent-ding-DIY.md" 2>/dev/null || true
  state_add files "$ZELLIJ_LAYOUT_DIR/agent-ding-DIY.md"
fi

if [ "$DO_SHELL" = 1 ]; then
  RC=""
  case "${SHELL:-}" in
    */zsh) RC="$HOME/.zshrc"; SNIP="$ROOT/packages/shell/ai.zsh" ;;
    */bash) RC="$HOME/.bashrc"; SNIP="$ROOT/packages/shell/ai.bash" ;;
    *) RC="$HOME/.zshrc"; SNIP="$ROOT/packages/shell/ai.zsh" ;;
  esac
  if [ -f "$SNIP" ]; then
    mkdir -p "$DATA_DIR"
    install -m 644 "$SNIP" "$DATA_DIR/shell-helpers.sh"
    state_add files "$DATA_DIR/shell-helpers.sh"
    if [ -f "$RC" ] && grep -qF "$SHELL_MARKER" "$RC" 2>/dev/null; then
      log "shell helpers already sourced in $RC"
    else
      {
        echo ""
        echo "$SHELL_MARKER"
        echo "source \"$DATA_DIR/shell-helpers.sh\""
        echo "# <<< agent-ding shell <<<"
      } >>"$RC"
      state_add markers "shell_rc:$RC"
      log "appended source line → $RC"
    fi
  fi
fi

if [ "$DO_GHOSTTY" = 1 ] && [[ "$(uname -s)" == "Darwin" ]]; then
  GHOSTTY_CFG="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
  mkdir -p "$(dirname "$GHOSTTY_CFG")"
  MARKER="# >>> agent-ding ghostty >>>"
  if [ -f "$GHOSTTY_CFG" ] && grep -qF "$MARKER" "$GHOSTTY_CFG" 2>/dev/null; then
    log "ghostty snippet already present"
  else
    {
      echo ""
      echo "$MARKER"
      cat "$ROOT/packages/ghostty/config.snippet"
      echo "# <<< agent-ding ghostty <<<"
    } >>"$GHOSTTY_CFG"
    state_add markers "ghostty:$GHOSTTY_CFG"
    log "appended ghostty snippet → $GHOSTTY_CFG"
  fi
fi

if [ "$WITH_ZA" = 1 ]; then
  log "install zellij-attention"
  mkdir -p "$ZELLIJ_PLUGIN_DIR"
  WASM="$ZELLIJ_PLUGIN_DIR/zellij-attention.wasm"
  curl -fsSL -L -o "$WASM" \
    "https://github.com/KiryuuLight/zellij-attention/releases/latest/download/zellij-attention.wasm"
  state_add plugins "$WASM"
  ZCFG="$HOME/.config/zellij/config.kdl"
  ZA_MARK="// >>> agent-ding zellij-attention >>>"
  if [ -f "$ZCFG" ] && grep -qF "$ZA_MARK" "$ZCFG" 2>/dev/null; then
    log "zellij-attention load_plugins already marked"
  elif [ -f "$ZCFG" ]; then
    # Best-effort: append load_plugins block if none; else print instructions
    if ! grep -q 'load_plugins' "$ZCFG"; then
      {
        echo ""
        echo "$ZA_MARK"
        cat <<'KDL'
load_plugins {
    "file:~/.config/zellij/plugins/zellij-attention.wasm" {
        enabled "true"
        waiting_icon "⏳"
        completed_icon "✅"
    }
}
KDL
        echo "// <<< agent-ding zellij-attention <<<"
      } >>"$ZCFG"
      state_add markers "zellij_cfg:$ZCFG"
      log "appended load_plugins → $ZCFG"
    else
      log "add load_plugins entry manually (see packages/layouts/zellij-config.snippet.kdl)"
      state_add markers "zellij_cfg_manual:$ZCFG"
    fi
  fi
fi

if [ "$WITH_HOOKS" = 1 ]; then
  log "merge done-only agent hooks"
  python3 - "$ROOT" <<'PY'
import json, re, sys
from pathlib import Path
root = Path(sys.argv[1])
state_path = Path.home() / ".local/share/agent-ding/install-state.json"

def load_state():
    if state_path.exists():
        return json.loads(state_path.read_text())
    return {"version": 1, "hooks": []}

def save_state(st):
    state_path.parent.mkdir(parents=True, exist_ok=True)
    state_path.write_text(json.dumps(st, indent=2) + "\n")

st = load_state()
hooks_log = st.setdefault("hooks", [])

# Claude
cp = Path.home() / ".claude/settings.json"
if cp.exists():
    data = json.loads(cp.read_text())
    hooks = data.setdefault("hooks", {})
    new_stop = []
    for e in hooks.get("Stop", []):
        cmds = " ".join(h.get("command", "") for h in e.get("hooks", []))
        if "agent-ding" in cmds or "handle-claude-hook" in cmds:
            continue
        new_stop.append(e)
    entry = {"hooks": [{"type": "command", "command": "agent-ding claude"}]}
    new_stop.append(entry)
    hooks["Stop"] = new_stop
    data["hooks"] = hooks
    cp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    tag = "claude:Stop:agent-ding claude"
    if tag not in hooks_log:
        hooks_log.append(tag)
    print("Claude Stop → agent-ding claude")
else:
    print("skip Claude (no ~/.claude/settings.json)")

# Grok
gp = Path.home() / ".grok/config.toml"
frag = (root / "hooks/grok.config.fragment.toml").read_text()
mark = "# >>> agent-ding grok >>>"
if gp.exists():
    text = gp.read_text()
    if mark in text:
        print("Grok fragment already present")
    else:
        # strip old diy notification blocks that call agent-ding
        if "agent-ding grok" in text and mark not in text:
            # leave as-is if user already has working block
            print("Grok already references agent-ding (manual)")
        else:
            gp.write_text(text.rstrip() + "\n\n" + mark + "\n" + frag + "\n# <<< agent-ding grok <<<\n")
            tag = "grok:config:agent-ding"
            if tag not in hooks_log:
                hooks_log.append(tag)
            print("appended Grok turn_complete hook")
else:
    print("skip Grok (no ~/.grok/config.toml)")

st["hooks"] = hooks_log
save_state(st)
PY
fi

state_add markers "repo:$ROOT"
log "done. state → $STATE_FILE"
echo ""
echo "Test:     agent-ding claude"
echo "Uninstall: $ROOT/uninstall.sh"
echo "Interview: $ROOT/setup.sh"
echo "Agents:    https://github.com/levi-qiao/agent-ding/blob/main/docs/for-agents.md"
