# For coding agents (setup interview)

**Canonical URL to open / fetch:**  
https://github.com/levi-qiao/agent-ding/blob/main/docs/for-agents.md

When the user pastes this repo (or this file) into a coding agent, the agent should **interview the owner**, detect the machine, and only install what they want. Do not dump every feature.

## Mission

Install/configure **agent-ding** so coding agents ding on **turn complete only**, with optional layouts. Prefer **DIY** (user controls panes) over forcing a fixed workspace.

## Non-negotiables

1. **English-only** ding text (`Done`, not Chinese).
2. **Done-only** hooks — never wire permission / idle spam by default.
3. **Leave no garbage** — use `./uninstall.sh` paths; track installs in state file.
4. **Modular** — install only packages the owner accepts.
5. Ask before writing hooks, shell rc, or Ghostty/Zellij config.

## Detect first (run these)

```bash
uname -s
command -v brew ghostty zellij tmux claude grok agy codex terminal-notifier agent-ding 2>/dev/null
echo "TERM_PROGRAM=${TERM_PROGRAM:-}"
echo "ZELLIJ=${ZELLIJ:-}"
test -f ~/.claude/settings.json && echo has_claude_settings
test -f ~/.grok/config.toml && echo has_grok_config
test -d ~/.config/zellij && echo has_zellij_config
ls ~/.config/zellij/layouts 2>/dev/null
```

## Interview script (ask the owner)

Ask **one block of questions** (or interactive), then implement:

| # | Question | Default if unsure |
|---|----------|-------------------|
| 1 | Want **desktop dings** when an agent finishes? | Yes |
| 2 | Which agents? (`claude` / `grok` / `agy` / `codex` / none) | Detect installed CLIs |
| 3 | Terminal in use? (Ghostty / iTerm / others — multi-ok) | `$TERM_PROGRAM` |
| 4 | Use **Zellij** (or tmux) for multi-pane? | Detect `zellij` |
| 5 | Want **starter layouts** (`ai-workspace` / `groks`) or **DIY only** (hooks only)? | DIY only if they already have layouts |
| 6 | Want shell helpers `ai` / `groks`? | Only if they want layouts |
| 7 | Want **tab ✅ marks** (zellij-attention)? | Optional; only if Zellij |
| 8 | OK to merge **Claude Stop** / **Grok turn_complete** hooks? | Require explicit yes |

Emphasize: **panes are DIY** — sample layouts are templates; they can edit `*.kdl` freely.

## Stack (what each piece is)

| Piece | Required? | Role |
|-------|-----------|------|
| **agent-ding** (notify) | Core | Fires “Done” toast + optional BEL |
| **terminal-notifier** (macOS) | For branded icons | `brew install terminal-notifier` |
| **Terminal app** (Ghostty / iTerm / …) | Host | Where agents run; multi-supported |
| **Zellij** (or plain panes) | Optional | Multi-agent tabs/panes |
| **Layouts** | Optional | Starter KDL; fully user-editable |
| **zellij-attention** | Optional | Tab ✅ when done |
| **Agent hooks** | Per agent | Claude `Stop`, Grok `turn_complete` only |

Do **not** require Ghostty. Prefer “whatever terminal they already use”.

## Install commands (after answers)

Clone once:

```bash
git clone https://github.com/levi-qiao/agent-ding.git
cd agent-ding
```

Examples:

```bash
# Notify only
./install.sh --only notify

# Notify + sample layouts
./install.sh --only notify --only layouts   # invalid; use:
./install.sh                  # default: notify + layouts

# Everything optional
./install.sh --all --with-hooks --with-zellij-attention

# Interactive interview (preferred)
./setup.sh
```

macOS brand icons need network once (`agent-ding-icons`).

## Wire agents (done-only)

**Claude** — ensure `Stop` runs `agent-ding claude` (keep existing unrelated hooks like rtk).

**Grok** — append fragment from `hooks/grok.config.fragment.toml`.

**Agy / Codex** — only if owner wants; Codex desktop often has its own notifications.

## DIY layouts

Point owner to:

- `packages/layouts/ai-workspace.kdl` — example multi-agent tab
- `packages/layouts/DIY.md` — how to add/remove panes

Rule: `command="…"` panes with `close_on_exit=false` re-run on Enter.

## Verify

```bash
agent-ding claude
agent-ding grok "fixed tests"
./uninstall.sh --dry-run   # show what would be removed
```

## Uninstall (no leftovers)

```bash
./uninstall.sh             # uses install-state.json
./uninstall.sh --purge     # also drop brand apps/icons data dir
```

Never leave half-merged hooks: uninstall removes only **agent-ding** hook entries it added.

## Out of scope

- Exact click → Zellij pane focus (document limitation; use tab marks)
- Non-done events (permission/idle) unless owner explicitly asks
