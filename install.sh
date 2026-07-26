#!/usr/bin/env bash
# Modular installer for agent-ding. Records state for clean uninstall.
#
# Usage:
#   ./install.sh                         # notify + layouts
#   ./install.sh --all
#   ./install.sh --only notify
#   ./install.sh --only layouts
#   ./install.sh --only shell
#   ./install.sh --only ghostty
#   ./install.sh --only notify --with-hooks
#   ./install.sh --only notify --with-zellij-attention
#   ./setup.sh                           # interactive interview (TTY)
#
# Coding agents: read docs/for-agents.md — interview in chat, then this script.
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
DING_BIN="$BIN_DIR/agent-ding"

ONLY=""
WITH_HOOKS=0
WITH_ZA=0
DO_NOTIFY=0
DO_LAYOUTS=0
DO_SHELL=0
DO_GHOSTTY=0

usage() {
  cat <<'EOF'
Usage:
  ./install.sh                         # notify + layouts
  ./install.sh --all
  ./install.sh --only notify|layouts|shell|ghostty
  ./install.sh --only notify --with-hooks
  ./install.sh --only notify --with-zellij-attention
  ./setup.sh                           # interactive interview

Coding agents: https://github.com/levi-qiao/agent-ding/blob/main/docs/for-agents.md
EOF
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
        *) echo "unknown package: ${2:-} (notify|layouts|shell|ghostty)" >&2; exit 2 ;;
      esac
      shift 2
      ;;
    --with-hooks) WITH_HOOKS=1; shift ;;
    --with-zellij-attention) WITH_ZA=1; shift ;;
    --yes) shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [ "$DO_NOTIFY$DO_LAYOUTS$DO_SHELL$DO_GHOSTTY" = "0000" ]; then
  if [ "$WITH_HOOKS" = 1 ] || [ "$WITH_ZA" = 1 ]; then
    # allow flags-only on top of existing install
    :
  else
    DO_NOTIFY=1
    DO_LAYOUTS=1
  fi
fi

log() { printf '→ %s\n' "$*"; }
state_init

find_tn_app() {
  if [ -n "${TERMINAL_NOTIFIER_APP:-}" ] && [ -d "$TERMINAL_NOTIFIER_APP" ]; then
    echo "$TERMINAL_NOTIFIER_APP"
    return
  fi
  local c
  c="$(command -v terminal-notifier 2>/dev/null || true)"
  if [ -n "$c" ]; then
    # Homebrew: bin is a symlink into the .app
    local real
    real="$(readlink "$c" 2>/dev/null || true)"
    if [ -n "$real" ]; then
      case "$real" in
        /*) ;;
        *) real="$(cd "$(dirname "$c")" && cd "$(dirname "$real")" && pwd)/$(basename "$real")" ;;
      esac
      if [[ "$real" == *".app/"* ]]; then
        echo "${real%%.app/*}.app"
        return
      fi
    fi
  fi
  local d
  for d in /opt/homebrew/Cellar/terminal-notifier/*/terminal-notifier.app \
           /usr/local/Cellar/terminal-notifier/*/terminal-notifier.app; do
    # shellcheck disable=SC2086
    if [ -d $d ]; then echo $d; return; fi
  done
  return 1
}

if [ "$DO_NOTIFY" = 1 ]; then
  log "install notify → $BIN_DIR"
  mkdir -p "$BIN_DIR" "$DATA_DIR"
  for b in agent-ding agent-ding-icons agent-ding-build-apps; do
    install -m 755 "$ROOT/packages/notify/bin/$b" "$BIN_DIR/$b"
    state_add bins "$BIN_DIR/$b"
  done
  if [[ "$(uname -s)" == "Darwin" ]]; then
    if ! find_tn_app >/dev/null 2>&1; then
      if command -v brew >/dev/null 2>&1; then
        log "brew install terminal-notifier"
        brew install terminal-notifier || log "warn: brew install failed"
      else
        log "warn: install terminal-notifier for branded icons (brew install terminal-notifier)"
      fi
    fi
    TN_APP="$(find_tn_app || true)"
    if [ -n "$TN_APP" ]; then
      export TERMINAL_NOTIFIER_APP="$TN_APP"
    fi
    log "build brand icons + apps"
    "$BIN_DIR/agent-ding-icons" || log "warn: icons failed (network?)"
    "$BIN_DIR/agent-ding-build-apps" || log "warn: app build failed"
    state_add markers "data_dir:$DATA_DIR"
  else
    log "non-macOS: notify-send / fallback (no brand .app)"
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
  if [ -f "$ROOT/packages/layouts/DIY.md" ]; then
    install -m 644 "$ROOT/packages/layouts/DIY.md" "$ZELLIJ_LAYOUT_DIR/agent-ding-DIY.md"
    state_add files "$ZELLIJ_LAYOUT_DIR/agent-ding-DIY.md"
  fi
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
      touch "$RC"
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
    touch "$GHOSTTY_CFG"
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
      log "NOTE: add zellij-attention to existing load_plugins (see packages/layouts/zellij-config.snippet.kdl)"
      state_add markers "zellij_cfg_manual:$ZCFG"
    fi
  else
    log "NOTE: no ~/.config/zellij/config.kdl yet — plugin wasm installed; add load_plugins when you create config"
  fi
fi

if [ "$WITH_HOOKS" = 1 ]; then
  if [ ! -x "$DING_BIN" ]; then
    log "hooks need notify first — installing notify"
    DO_NOTIFY=1
    # recurse only notify bits: install bins if missing
    mkdir -p "$BIN_DIR" "$DATA_DIR"
    for b in agent-ding agent-ding-icons agent-ding-build-apps; do
      install -m 755 "$ROOT/packages/notify/bin/$b" "$BIN_DIR/$b"
      state_add bins "$BIN_DIR/$b"
    done
  fi
  log "merge done-only hooks (absolute path: $DING_BIN)"
  DING_BIN="$DING_BIN" python3 - <<'PY'
import json, os
from pathlib import Path

ding = os.environ["DING_BIN"]
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
    cmd = f"{ding} claude"
    new_stop.append({"hooks": [{"type": "command", "command": cmd}]})
    hooks["Stop"] = new_stop
    data["hooks"] = hooks
    cp.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
    tag = f"claude:Stop:{cmd}"
    if tag not in hooks_log:
        hooks_log.append(tag)
    print(f"Claude Stop → {cmd}")
else:
    print("skip Claude (no ~/.claude/settings.json)")

# Grok — primary: lifecycle Stop in ~/.grok/hooks/ (same idea as Claude Stop).
# Do not rely on [ui.notifications] method="none": Grok 0.2.x treats that as
# turning notifications (and their hooks) off entirely.
gh_dir = Path.home() / ".grok" / "hooks"
if (Path.home() / ".grok").is_dir() or gh_dir.parent.exists():
    gh_dir.mkdir(parents=True, exist_ok=True)
    gh = gh_dir / "agent-ding.json"
    gh.write_text(
        json.dumps(
            {
                "hooks": {
                    "Stop": [
                        {
                            "hooks": [
                                {
                                    "type": "command",
                                    "command": f"{ding} grok",
                                }
                            ]
                        }
                    ]
                }
            },
            indent=2,
        )
        + "\n"
    )
    # stable tag (path is always ~/.grok/hooks/agent-ding.json)
    tag = "grok:hooks:agent-ding.json:Stop"
    # drop legacy tags from older installs
    hooks_log[:] = [
        h
        for h in hooks_log
        if h not in ("grok:config:agent-ding",)
        and not h.startswith("grok:hooks:/")
    ]
    if tag not in hooks_log:
        hooks_log.append(tag)
    print(f"Grok Stop → {ding} grok  ({gh})")

    # Strip legacy broken [ui.notifications] block (method=none) if present
    gp = Path.home() / ".grok" / "config.toml"
    mark = "# >>> agent-ding grok >>>"
    if gp.exists():
        import re

        text = gp.read_text()
        if mark in text:
            text2 = re.sub(
                r"\n?# >>> agent-ding grok >>>.*?# <<< agent-ding grok <<<\n?",
                "\n",
                text,
                flags=re.S,
            )
            gp.write_text(text2)
            print("stripped legacy Grok ui.notifications agent-ding block")
else:
    print("skip Grok (no ~/.grok)")

st["hooks"] = hooks_log
save_state(st)
PY
fi

state_add markers "repo:$ROOT"
log "done. state → $STATE_FILE"
echo ""
echo "Test:      $DING_BIN claude"
echo "Uninstall: $ROOT/uninstall.sh"
echo "Agents:    https://github.com/levi-qiao/agent-ding/blob/main/docs/for-agents.md"
