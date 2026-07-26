#!/usr/bin/env bash
# Interactive interview (TTY). Coding agents should use docs/for-agents.md instead.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

have() { command -v "$1" >/dev/null 2>&1; }

echo "agent-ding setup"
echo "================"
echo "Detecting…"
echo "  OS:           $(uname -s)"
echo "  TERM_PROGRAM: ${TERM_PROGRAM:-unknown}"
for c in ghostty zellij claude grok agy codex brew; do
  printf '  %-12s %s\n' "$c" "$(have $c && echo yes || echo no)"
done
echo ""
echo "Tip for coding agents: use docs/for-agents.md (interview in chat)."
echo ""

ask_yn() {
  local prompt="$1" default="${2:-y}" ans hint="[Y/n]"
  [ "$default" = "n" ] && hint="[y/N]"
  read -r -p "$prompt $hint " ans || true
  ans="$(printf '%s' "${ans:-$default}" | tr '[:upper:]' '[:lower:]')"
  [[ "$ans" == y* ]]
}

DO_NOTIFY=0 DO_LAYOUTS=0 DO_SHELL=0 DO_GHOSTTY=0 WITH_HOOKS=0 WITH_ZA=0

ask_yn "Install desktop dings (notify)?" y && DO_NOTIFY=1

if have zellij; then
  if ask_yn "Install starter Zellij layouts (DIY-editable templates)?" n; then
    DO_LAYOUTS=1
    ask_yn "Install shell helpers (ai / groks)?" y && DO_SHELL=1
  fi
  ask_yn "Install zellij-attention (tab checkmarks)?" n && WITH_ZA=1
else
  echo "(no zellij — layouts skipped; notify works in any terminal)"
fi

if [[ "$(uname -s)" == "Darwin" ]] && { [[ "${TERM_PROGRAM:-}" == "ghostty" ]] || [ -d "/Applications/Ghostty.app" ]; }; then
  ask_yn "Append Ghostty config snippet?" n && DO_GHOSTTY=1
fi

if have claude || have grok || [ -f "$HOME/.claude/settings.json" ] || [ -f "$HOME/.grok/config.toml" ]; then
  ask_yn "Wire done-only hooks for detected agents?" y && WITH_HOOKS=1
fi

echo ""
echo "Plan:"
[ "$DO_NOTIFY" = 1 ] && echo "  • notify"
[ "$DO_LAYOUTS" = 1 ] && echo "  • layouts"
[ "$DO_SHELL" = 1 ] && echo "  • shell"
[ "$DO_GHOSTTY" = 1 ] && echo "  • ghostty"
[ "$WITH_ZA" = 1 ] && echo "  • zellij-attention"
[ "$WITH_HOOKS" = 1 ] && echo "  • hooks (done-only, absolute paths)"
[ "$DO_NOTIFY$DO_LAYOUTS$DO_SHELL$DO_GHOSTTY$WITH_ZA$WITH_HOOKS" = "000000" ] && { echo "  (nothing)"; exit 0; }

ask_yn "Proceed?" y || { echo "aborted"; exit 1; }

[ "$DO_NOTIFY" = 1 ] && ./install.sh --only notify
[ "$DO_LAYOUTS" = 1 ] && ./install.sh --only layouts
[ "$DO_SHELL" = 1 ] && ./install.sh --only shell
[ "$DO_GHOSTTY" = 1 ] && ./install.sh --only ghostty

EXTRA=()
[ "$WITH_ZA" = 1 ] && EXTRA+=(--with-zellij-attention)
[ "$WITH_HOOKS" = 1 ] && EXTRA+=(--with-hooks)
if [ ${#EXTRA[@]} -gt 0 ]; then
  ./install.sh --only notify "${EXTRA[@]}"
fi

echo ""
echo "Done. Test: agent-ding claude"
echo "Uninstall: ./uninstall.sh   |   ./uninstall.sh --purge"
echo "Agents doc: docs/for-agents.md"
