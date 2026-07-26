#!/usr/bin/env bash
# Remove agent-ding install artifacts tracked in install-state.json.
# Leaves unrelated user config alone.
#
#   ./uninstall.sh
#   ./uninstall.sh --dry-run
#   ./uninstall.sh --purge     # also delete data dir + brand apps/icons
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=lib/state.sh
source "$ROOT/lib/state.sh"

DRY=0
PURGE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --purge) PURGE=1; shift ;;
    -h|--help)
      sed -n '2,8p' "$0" | sed 's/^# \?//'
      exit 0
      ;;
    *) echo "unknown: $1" >&2; exit 2 ;;
  esac
done

log() { printf '→ %s\n' "$*"; }
run() {
  if [ "$DRY" = 1 ]; then
    echo "DRY $*"
  else
    eval "$@"
  fi
}

if [ ! -f "$STATE_FILE" ]; then
  log "no state file ($STATE_FILE) — nothing tracked"
  log "tip: remove manually: ~/.local/bin/agent-ding*  ~/.local/share/agent-ding"
  exit 0
fi

log "reading $STATE_FILE"

while IFS= read -r p; do
  [ -z "$p" ] && continue
  log "bin $p"
  run "rm -f \"$p\""
done < <(state_get bins)

while IFS= read -r p; do
  [ -z "$p" ] && continue
  log "layout $p"
  run "rm -f \"$p\""
done < <(state_get layouts)

while IFS= read -r p; do
  [ -z "$p" ] && continue
  log "file $p"
  run "rm -f \"$p\""
done < <(state_get files)

while IFS= read -r p; do
  [ -z "$p" ] && continue
  log "plugin $p"
  run "rm -f \"$p\""
done < <(state_get plugins)

# Markers: strip blocks from rc / configs
while IFS= read -r m; do
  [ -z "$m" ] && continue
  case "$m" in
    shell_rc:*)
      RC="${m#shell_rc:}"
      log "strip shell block in $RC"
      if [ "$DRY" = 1 ]; then
        echo "DRY strip agent-ding shell markers in $RC"
      else
        python3 - "$RC" <<'PY'
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
if not p.exists():
    raise SystemExit(0)
text = p.read_text()
text2 = re.sub(
    r"\n?# >>> agent-ding shell >>>.*?# <<< agent-ding shell <<<\n?",
    "\n",
    text,
    flags=re.S,
)
p.write_text(text2)
PY
      fi
      ;;
    ghostty:*)
      CFG="${m#ghostty:}"
      log "strip ghostty block in $CFG"
      if [ "$DRY" = 1 ]; then
        echo "DRY strip ghostty markers"
      else
        python3 - "$CFG" <<'PY'
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
if not p.exists():
    raise SystemExit(0)
text = p.read_text()
text2 = re.sub(
    r"\n?# >>> agent-ding ghostty >>>.*?# <<< agent-ding ghostty <<<\n?",
    "\n",
    text,
    flags=re.S,
)
p.write_text(text2)
PY
      fi
      ;;
    zellij_cfg:*)
      CFG="${m#zellij_cfg:}"
      log "strip zellij-attention block in $CFG"
      if [ "$DRY" = 1 ]; then
        echo "DRY strip zellij markers"
      else
        python3 - "$CFG" <<'PY'
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
if not p.exists():
    raise SystemExit(0)
text = p.read_text()
text2 = re.sub(
    r"\n?// >>> agent-ding zellij-attention >>>.*?// <<< agent-ding zellij-attention <<<\n?",
    "\n",
    text,
    flags=re.S,
)
p.write_text(text2)
PY
      fi
      ;;
    data_dir:*|repo:*|zellij_cfg_manual:*)
      ;;
    *)
      log "marker $m (no auto-clean)"
      ;;
  esac
done < <(state_get markers)

# Hooks: remove agent-ding entries we added
while IFS= read -r h; do
  [ -z "$h" ] && continue
  log "hook $h"
  if [ "$DRY" = 1 ]; then
    echo "DRY remove $h"
    continue
  fi
  case "$h" in
    claude:*)
      python3 <<'PY'
import json
from pathlib import Path
p = Path.home() / ".claude/settings.json"
if not p.exists():
    raise SystemExit(0)
data = json.loads(p.read_text())
hooks = data.get("hooks") or {}
stop = []
for e in hooks.get("Stop", []):
    cmds = " ".join(x.get("command", "") for x in e.get("hooks", []))
    if "agent-ding" in cmds:
        continue
    stop.append(e)
if stop:
    hooks["Stop"] = stop
elif "Stop" in hooks:
    del hooks["Stop"]
data["hooks"] = hooks
p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")
print("removed Claude agent-ding Stop hooks")
PY
      ;;
    grok:hooks:*|grok:config:*)
      # Remove lifecycle hook file and/or legacy config markers
      GH="$HOME/.grok/hooks/agent-ding.json"
      if [ -f "$GH" ]; then
        run "rm -f \"$GH\""
        log "removed $GH"
      fi
      GP="$HOME/.grok/config.toml"
      if [ -f "$GP" ]; then
        python3 - "$GP" <<'PY'
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
text = p.read_text()
text2 = re.sub(
    r"\n?# >>> agent-ding grok >>>.*?# <<< agent-ding grok <<<\n?",
    "\n",
    text,
    flags=re.S,
)
p.write_text(text2)
print("stripped Grok agent-ding config markers (if any)")
PY
      fi
      ;;
    grok:*)
      # backward-compat for older install-state tags
      GH="$HOME/.grok/hooks/agent-ding.json"
      [ -f "$GH" ] && run "rm -f \"$GH\""
      GP="$HOME/.grok/config.toml"
      if [ -f "$GP" ]; then
        python3 - "$GP" <<'PY'
import re, sys
from pathlib import Path
p = Path(sys.argv[1])
if p.exists():
    text = p.read_text()
    p.write_text(re.sub(
        r"\n?# >>> agent-ding grok >>>.*?# <<< agent-ding grok <<<\n?",
        "\n", text, flags=re.S,
    ))
print("stripped Grok agent-ding (legacy tag)")
PY
      fi
      ;;
  esac
done < <(state_get hooks)

if [ "$PURGE" = 1 ]; then
  DATA="${XDG_DATA_HOME:-$HOME/.local/share}/agent-ding"
  log "purge $DATA"
  run "rm -rf \"$DATA\""
else
  log "keep data dir (icons/apps). use --purge to delete"
  if [ "$DRY" = 0 ]; then
    state_clear
  fi
fi

if [ "$DRY" = 0 ] && [ "$PURGE" = 0 ]; then
  state_clear
fi

log "uninstall complete"
