# agent-ding shell helpers for bash — source from ~/.bashrc
export ZELLIJ_SOCKET_DIR="${ZELLIJ_SOCKET_DIR:-/tmp/zellij}"

ai() {
  if [[ -n "${ZELLIJ:-}" ]]; then
    echo "Already inside Zellij; switch tabs or open a new pane instead." >&2
    return 1
  fi
  mkdir -p "${ZELLIJ_SOCKET_DIR}"
  local name="${1:-$(basename "$PWD")}"
  name="$(echo "$name" | tr -c '[:alnum:]_-' '-')"
  if zellij list-sessions --no-formatting 2>/dev/null | grep -q "^${name} "; then
    zellij attach "$name"
    return
  fi
  zellij delete-session "$name" 2>/dev/null || true
  zellij attach --create "$name" options --default-layout ai-workspace
}

groks() {
  if [[ -n "${ZELLIJ:-}" ]]; then
    echo "Already inside Zellij; switch tabs or open a new pane instead." >&2
    return 1
  fi
  mkdir -p "${ZELLIJ_SOCKET_DIR}"
  local name="${1:-$(basename "$PWD")}-groks"
  name="$(echo "$name" | tr -c '[:alnum:]_-' '-')"
  if zellij list-sessions --no-formatting 2>/dev/null | grep -q "^${name} "; then
    zellij attach "$name"
    return
  fi
  zellij delete-session "$name" 2>/dev/null || true
  zellij attach --create "$name" options --default-layout groks-workspace
}
