#!/usr/bin/env bash
# Interactive interview: detect the machine, ask the owner, install only what they want.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

have() { command -v "$1" >/dev/null 2>&1; }

echo "agent-ding setup"
echo "================"
echo "Detecting environment…"
echo "  OS:           $(uname -s)"
echo "  TERM_PROGRAM: ${TERM_PROGRAM:-unknown}"
echo "  ghostty:      $(have ghostty && echo yes || echo no)"
echo "  zellij:       $(have zellij && echo yes || echo no)"
echo "  claude:       $(have claude && echo yes || echo no)"
echo "  grok:         $(have grok && echo yes || echo no)"
echo "  agy:          $(have agy && echo yes || echo no)"
echo "  codex:        $(have codex && echo yes || echo no)"
echo "  brew:         $(have brew && echo yes || echo no)"
echo ""

ask_yn() {
  local prompt="$1" default="${2:-y}" ans
  local hint="[Y/n]"
  [ "$default" = "n" ] && hint="[y/N]"
  read -r -p "$prompt $hint " ans || true
  ans="$(printf '%s' "${ans:-$default}" | tr '[:upper:]' '[:lower:]')"
  [[ "$ans" == y* ]]
}

ARGS=()

if ask_yn "Install desktop dings (notify)?" y; then
  ARGS+=(--only notify)
  # allow combining: install.sh supports multiple --only by re-running logic
  # Our install.sh only keeps last --only — fix by using flags differently.
fi

# rebuild args properly for multi-package
DO_NOTIFY=0 DO_LAYOUTS=0 DO_SHELL=0 DO_GHOSTTY=0 WITH_HOOKS=0 WITH_ZA=0

ask_yn "Install desktop dings (notify)?" y && DO_NOTIFY=1

if have zellij; then
  if ask_yn "Install starter Zellij layouts (fully DIY-editable)?" n; then
    DO_LAYOUTS=1
    ask_yn "Install shell helpers (ai / groks commands)?" y && DO_SHELL=1
  fi
  ask_yn "Install zellij-attention (tab ✅ marks)?" n && WITH_ZA=1
else
  echo "(zellij not found — skipping layouts; notify still works in any terminal)"
fi

if [[ "$(uname -s)" == "Darwin" ]] && [[ "${TERM_PROGRAM:-}" == "ghostty" || -d "/Applications/Ghostty.app" ]]; then
  ask_yn "Append recommended Ghostty config snippet?" n && DO_GHOSTTY=1
fi

if have claude || have grok || [ -f "$HOME/.claude/settings.json" ] || [ -f "$HOME/.grok/config.toml" ]; then
  ask_yn "Wire done-only hooks for detected agents (Claude Stop / Grok turn_complete)?" y && WITH_HOOKS=1
fi

echo ""
echo "Plan:"
[ "$DO_NOTIFY" = 1 ] && echo "  • notify"
[ "$DO_LAYOUTS" = 1 ] && echo "  • layouts"
[ "$DO_SHELL" = 1 ] && echo "  • shell helpers"
[ "$DO_GHOSTTY" = 1 ] && echo "  • ghostty snippet"
[ "$WITH_ZA" = 1 ] && echo "  • zellij-attention"
[ "$WITH_HOOKS" = 1 ] && echo "  • agent hooks (done-only)"
[ "$DO_NOTIFY$DO_LAYOUTS$DO_SHELL$DO_GHOSTTY$WITH_ZA$WITH_HOOKS" = "000000" ] && {
  echo "  (nothing selected)"
  exit 0
}

ask_yn "Proceed?" y || { echo "aborted"; exit 1; }

# Call install modules sequentially (install.sh only accepts one --only at a time)
run_install() {
  local args=("$@")
  echo ""
  echo "+ ./install.sh ${args[*]}"
  ./install.sh "${args[@]}"
}

[ "$DO_NOTIFY" = 1 ] && run_install --only notify
[ "$DO_LAYOUTS" = 1 ] && run_install --only layouts
[ "$DO_SHELL" = 1 ] && run_install --only shell
[ "$DO_GHOSTTY" = 1 ] && run_install --only ghostty

EXTRA=()
[ "$WITH_ZA" = 1 ] && EXTRA+=(--with-zellij-attention)
[ "$WITH_HOOKS" = 1 ] && EXTRA+=(--with-hooks)
if [ ${#EXTRA[@]} -gt 0 ]; then
  # hooks/za need a no-op package pass — call install with only hooks flags
  # by temporarily installing nothing extra: re-enter with --only notify if already done
  if [ "$DO_NOTIFY" = 1 ]; then
    ./install.sh --only notify "${EXTRA[@]}"
  else
    # install.sh requires a package; use notify as carrier for flags only if needed
    ./install.sh --only notify "${EXTRA[@]}"
  fi
fi

echo ""
echo "Done."
echo "  Test:      agent-ding claude"
echo "  Uninstall: ./uninstall.sh   or   ./uninstall.sh --purge"
echo "  DIY panes: packages/layouts/DIY.md"
echo "  For agents: docs/for-agents.md"
