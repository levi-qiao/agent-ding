# agent-ding shell helpers for bash — source from ~/.bashrc

export ZELLIJ_SOCKET_DIR="${ZELLIJ_SOCKET_DIR:-/tmp/zellij}"

# Locked mode so Cmd/Ctrl+V image paste reaches Claude/Grok. Ctrl+g = toggle.
_agent_ding_zellij_create() {
  local name="$1" layout="$2"
  zellij delete-session "$name" 2>/dev/null || true
  zellij attach --create "$name" options \
    --default-layout "$layout" \
    --default-mode locked
}

ai() {
  if [[ -n "${ZELLIJ:-}" ]]; then
    echo "Already inside Zellij; switch tabs or open a new pane instead." >&2
    echo "Tip: Ctrl+g → locked mode so Claude can receive Cmd+V image paste." >&2
    return 1
  fi
  mkdir -p "${ZELLIJ_SOCKET_DIR}"
  local name="${1:-$(basename "$PWD")}"
  name="$(printf '%s' "$name" | tr -c '[:alnum:]_-' '-')"
  if zellij list-sessions --no-formatting 2>/dev/null | grep -q "^${name} "; then
    zellij attach "$name"
    echo "Attached existing session. If paste/images fail: press Ctrl+g (locked mode)." >&2
    return
  fi
  _agent_ding_zellij_create "$name" ai-workspace
}

groks() {
  if [[ -n "${ZELLIJ:-}" ]]; then
    echo "Already inside Zellij; switch tabs or open a new pane instead." >&2
    return 1
  fi
  mkdir -p "${ZELLIJ_SOCKET_DIR}"
  local name="${1:-$(basename "$PWD")}-groks"
  name="$(printf '%s' "$name" | tr -c '[:alnum:]_-' '-')"
  if zellij list-sessions --no-formatting 2>/dev/null | grep -q "^${name} "; then
    zellij attach "$name"
    echo "Attached existing session. If paste/images fail: press Ctrl+g (locked mode)." >&2
    return
  fi
  _agent_ding_zellij_create "$name" groks-workspace
}
