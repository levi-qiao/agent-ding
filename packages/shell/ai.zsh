# agent-ding shell helpers — source from ~/.zshrc
#   source /path/to/agent-ding/packages/shell/ai.zsh

export ZELLIJ_SOCKET_DIR="${ZELLIJ_SOCKET_DIR:-/tmp/zellij}"

# Locked mode is required so Cmd/Ctrl+V (image paste into Claude/Grok) reaches
# the agent. Ctrl+g toggles back to Zellij normal mode for pane/tab control.
_agent_ding_zellij_create() {
  local name="$1" layout="$2"
  zellij delete-session "$name" 2>/dev/null || true
  # --default-mode locked: pass keystrokes (incl. Cmd+V image paste) to panes
  zellij attach --create "$name" options \
    --default-layout "$layout" \
    --default-mode locked
}

# Project-scoped multi-agent workspace (Grok + Claude + Agy)
ai() {
  if [[ -n "${ZELLIJ:-}" ]]; then
    print -u2 "Already inside Zellij; switch tabs or open a new pane instead."
    print -u2 "Tip: Ctrl+g → locked mode so Claude can receive Cmd+V image paste."
    return 1
  fi
  mkdir -p "${ZELLIJ_SOCKET_DIR}"
  local name="${1:-${PWD:t}}"
  name="${name//[^[:alnum:]_-]/-}"
  if zellij list-sessions --no-formatting 2>/dev/null | command grep -q "^${name} "; then
    zellij attach "$name"
    print -u2 "Attached existing session. If paste/images fail: press Ctrl+g (locked mode)."
    return
  fi
  _agent_ding_zellij_create "$name" ai-workspace
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
    print -u2 "Attached existing session. If paste/images fail: press Ctrl+g (locked mode)."
    return
  fi
  _agent_ding_zellij_create "$name" groks-workspace
}
