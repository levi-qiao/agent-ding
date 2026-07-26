# For coding agents — setup playbook

**If you are an AI coding agent and the user only gave you a link to this repo or this file: this document is your runbook.**

Canonical URL:

```text
https://github.com/levi-qiao/agent-ding/blob/main/docs/for-agents.md
```

## Your job

1. **Interview the owner** (in the chat UI).
2. **Detect** what is already installed.
3. **Install only** what they accept.
4. **Wire done-only hooks** with **absolute paths**.
5. **Verify** with a test ding.
6. Tell them how to **uninstall cleanly**.

Do **not** run interactive `./setup.sh` (needs a real TTY). You ask; then you run `./install.sh` flags.

## Non-negotiables

| Rule | Detail |
|------|--------|
| English only | Toast body default is `Done` |
| Done-only | Claude `Stop` / Grok `turn_complete` — **no** permission/idle spam |
| Absolute paths in hooks | `~/.local/bin/agent-ding` may be missing from agent PATH |
| No garbage | Use installer state; uninstall with `./uninstall.sh` |
| DIY panes | Sample layouts optional; never overwrite without asking |
| Ask first | Hooks, shell rc, Ghostty/Zellij config need explicit yes |

## Step 0 — get the code

```bash
git clone https://github.com/levi-qiao/agent-ding.git
cd agent-ding
# or: if already cloned, cd into the repo root
```

## Step 1 — detect (run)

```bash
uname -s
echo "TERM_PROGRAM=${TERM_PROGRAM:-}"
echo "SHELL=${SHELL:-}"
echo "PATH has .local/bin?"; echo ":$PATH:" | grep -q ':.*\.local/bin:' && echo yes || echo no
for c in brew ghostty zellij tmux claude grok agy codex terminal-notifier agent-ding; do
  printf '%-18s %s\n' "$c" "$(command -v $c 2>/dev/null || echo MISSING)"
done
test -f "$HOME/.claude/settings.json" && echo "claude_settings=yes" || echo "claude_settings=no"
test -f "$HOME/.grok/config.toml" && echo "grok_config=yes" || echo "grok_config=no"
test -d "$HOME/.config/zellij" && echo "zellij_config=yes" || echo "zellij_config=no"
ls "$HOME/.config/zellij/layouts" 2>/dev/null || true
```

## Step 2 — interview the owner

Ask clearly (one message is fine):

1. **Desktop ding** when an agent finishes a turn? (default: yes)
2. **Which agents** to wire? (offer only ones you detected: Claude / Grok / Agy / Codex)
3. Using **Zellij** (or happy with current panes)?  
   - Want **sample layouts** (`ai-workspace` / `groks`) or **hooks only** (DIY panes)?
4. Want optional **shell helpers** `ai` / `groks`? (only if layouts)
5. Want **tab ✅ marks** (zellij-attention)? (only if Zellij)
6. Using **Ghostty** and OK to append a small config snippet? (optional)
7. Confirm: OK to edit Claude/Grok config for **done-only** hooks?

Emphasize: panes/layouts are **DIY** — samples are templates they can edit or ignore.

## Step 3 — install packages

From repo root, run **one or more** (each `--only` is a separate invocation if needed):

```bash
# Core (almost always)
./install.sh --only notify

# Optional
./install.sh --only layouts
./install.sh --only shell
./install.sh --only ghostty

# Optional plugin + hooks (after notify is installed)
./install.sh --only notify --with-zellij-attention
./install.sh --only notify --with-hooks
```

Or combined optional flags after notify exists:

```bash
./install.sh --only notify --with-hooks --with-zellij-attention
```

**macOS:** installer tries `brew install terminal-notifier` if missing (needed for brand icons).

**Linux:** notify-send fallback; brand `.app` icons are macOS-only.

## Step 4 — hooks (critical: absolute path)

Let `DING="$HOME/.local/bin/agent-ding"`.

### Claude (`~/.claude/settings.json`)

- Keep existing hooks (e.g. rtk).
- Ensure a `Stop` entry runs: `"$HOME/.local/bin/agent-ding claude"`  
  (expand `$HOME` to a real path when writing JSON, e.g. `/Users/name/.local/bin/agent-ding claude`)
- Remove older noisy notify hooks if the owner agrees (hellolib `handle-claude-hook`, etc.).

`--with-hooks` does this merge for Claude when settings exist; **verify** the written command is absolute or that `~/.local/bin` is on the hook PATH. Prefer absolute.

### Grok (`~/.grok/hooks/agent-ding.json`)

**Primary (reliable):** lifecycle `Stop` — same idea as Claude. Fragment: `hooks/grok.hooks.json`.

```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "/Users/YOU/.local/bin/agent-ding grok"
      }]
    }]
  }
}
```

`--with-hooks` writes this file when `~/.grok` exists.

**Do not** set `[ui.notifications] method = "none"` expecting hooks still to run — on Grok Build 0.2.x that **disables the whole notification pipeline** (including `[[ui.notifications.hooks]]`). Optional secondary fragment `hooks/grok.config.fragment.toml` uses `method = "auto"` only if the owner wants `$GROK_MESSAGE` toasts *in addition* to Stop (may double-ding).

### Agy / Codex

Only if owner asked.

- **Codex:** often already has `notify = [..., "turn-ended"]` (desktop app). Do **not** replace it with agent-ding unless the owner wants the brand toast *instead of* Codex’s own.
- **Agy / Antigravity CLI:** no stable done-hook surface in settings today — install bins/icons only; owner can call `agent-ding agy` manually or when Agy adds hooks.

## Step 5 — verify

```bash
"$HOME/.local/bin/agent-ding" claude
"$HOME/.local/bin/agent-ding" grok "fixed tests"
./uninstall.sh --dry-run
```

Owner should see a toast: `Title` + `project · Done` (English).

If no toast on macOS: System Settings → Notifications → allow the brand apps (Claude / Grok / Agy / Codex).

## Step 6 — tell the owner

- How to test: `agent-ding claude`
- How to uninstall: `cd agent-ding && ./uninstall.sh` or `./uninstall.sh --purge`
- DIY layouts: `packages/layouts/DIY.md`
- Click toast focuses the **terminal app**, not a specific Zellij pane; tab ✅ is optional via zellij-attention

## Stack reference (multi-support)

| Piece | Required? | Purpose |
|-------|-----------|---------|
| agent-ding notify | Core | Done toast |
| terminal-notifier | macOS branded icons | brew formula |
| Terminal app | Host | Ghostty / iTerm / … any |
| Zellij | Optional | Multi-pane |
| Sample layouts | Optional | Editable KDL templates |
| zellij-attention | Optional | Tab marks |
| Agent hooks | Per agent | Fire ding on complete |

## Uninstall

```bash
./uninstall.sh             # reverse tracked files/hooks
./uninstall.sh --purge     # also delete ~/.local/share/agent-ding
```

## Failure checklist

| Symptom | Fix |
|---------|-----|
| Hook runs but no toast | Absolute path to `agent-ding`; macOS notification permission for brand apps |
| `agent-ding: command not found` in hook | Use full path in hook command |
| Grok turn ends, no ding | Prefer `~/.grok/hooks/agent-ding.json` **Stop** (not only `ui.notifications`). Restart Grok after install. Avoid `method = "none"` |
| Grok dings as Claude Code | Fixed in ≥0.1.2: host remap (`GROK_AGENT` / hook env / PPID). Ensure `~/.grok/hooks/agent-ding.json` Stop → `agent-ding grok`. Prefer `compat.claude.hooks = false` |
| Icons look like Terminal | Run `agent-ding-icons && agent-ding-build-apps` on macOS |
| Layout not applied | New Zellij session after copying layouts; or DIY |
| Uninstall left stuff | Was installed without `./install.sh` — use `--purge` + manual hook edit |

## Out of scope

- Exact click → Zellij pane focus  
- Permission/idle notifications by default  

## Grok + Claude hook compatibility

Grok may set `[compat.claude] hooks = true` and **load `~/.claude/settings.json` hooks**.

If Claude has `Stop → agent-ding claude`, Grok turns would incorrectly ding as Claude Code.

**agent-ding mitigates this:** when `client=claude` but the host looks like Grok (`GROK_AGENT`, `GROK_HOOK_*`, `GROK_SESSION_ID`, parent process tree), it **remaps to Grok** and uses the Grok brand app / title. Always still install a **Grok-native** Stop → `agent-ding grok`. A shared notification group collapses double-fire into one toast.

Do not remove `compat.claude.hooks` solely for this unless the owner wants that — they may rely on Claude PreToolUse hooks (e.g. rtk) inside Grok. Prefer installing Grok’s own rtk/agent-ding under `~/.grok/hooks/` when compat is off.
