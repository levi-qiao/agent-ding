# agent-ding shell helpers — source from ~/.zshrc
#   source /path/to/agent-ding/packages/shell/ai.zsh

export ZELLIJ_SOCKET_DIR="${ZELLIJ_SOCKET_DIR:-/tmp/zellij}"

# Project-scoped multi-agent workspace (Grok + Claude + Agy)
ai() {
  if [[ -n "${ZELLIJ:-}" ]]; then
    print -u2 "Already inside Zellij; switch tabs or open a new pane instead."
    return 1
  fi
  mkdir -p "${ZELLIJ_SOCKET_DIR}"
  local name="${1:-${PWD:t}}"
  name="${name//[^[:alnum:]_-]/-}"
  if zellij list-sessions --no-formatting 2>/dev/null | command grep -q "^${name} "; then
    zellij attach "$name"
    return
  fi
  zellij delete-session "$name" 2>/dev/null || true
  zellij attach --create "$name" options --default-layout ai-workspace
}

# Dual-Grok workspace
groks() {
  if [[ -n "${ZELLIJ:-}" ]]; then
    print -u2 "Already inside Zellij; switch tabs or open a new pane instead."
    return 1
  fi
  mkdir -p "${ZELLIJ_SOCKET_DIR}"
  local name="${1:-${PWD:t}}-groks"
  name="${name//[^[:alnum:]_-]/-}"
  if zellij list-sessions --no-formatting 2>/dev/null | command grep -q "^${name} "; then
    zellij attach "$name"
    return
  fi
  zellij delete-session "$name" 2>/dev/null || true
  zellij attach --create "$name" options --default-layout groks-workspace
}
