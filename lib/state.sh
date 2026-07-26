#!/usr/bin/env bash
# Shared install-state helpers (sourced by install/uninstall).
# State file tracks every path we touch so uninstall leaves no garbage.

STATE_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/agent-ding"
STATE_FILE="${AGENT_DING_STATE:-$STATE_DIR/install-state.json}"

state_init() {
  mkdir -p "$STATE_DIR"
  if [ ! -f "$STATE_FILE" ]; then
    printf '%s\n' '{"version":1,"bins":[],"layouts":[],"files":[],"markers":[],"hooks":[],"plugins":[]}' >"$STATE_FILE"
  fi
}

# Append a unique string to a JSON string array field via python3
state_add() {
  local field="$1" value="$2"
  state_init
  python3 - "$STATE_FILE" "$field" "$value" <<'PY'
import json, sys
path, field, value = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    data = json.load(f)
arr = data.setdefault(field, [])
if value not in arr:
    arr.append(value)
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
}

state_get() {
  local field="$1"
  [ -f "$STATE_FILE" ] || return 0
  python3 - "$STATE_FILE" "$field" <<'PY'
import json, sys
path, field = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
for x in data.get(field, []):
    print(x)
PY
}

state_clear() {
  rm -f "$STATE_FILE"
}
