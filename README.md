# agent-ding

**Ding when your coding agent finishes.**

English-only. **Done-only** (not permission spam). Any terminal. Optional Zellij layouts (DIY). Modular install. Clean uninstall.

```text
agent turn completes  →  agent-ding  →  "MyProject · Done"
```

---

## For coding agents (one URL)

Paste this into any coding agent and ask it to set up agent-ding:

```text
https://github.com/levi-qiao/agent-ding/blob/main/docs/for-agents.md
```

Or open the repo — agents should read [`AGENTS.md`](./AGENTS.md) first.

The agent will **interview you**, detect installed tools, install only what you want, wire **done-only** hooks with absolute paths, and leave a clean `./uninstall.sh`.

---

## For humans

```bash
git clone https://github.com/levi-qiao/agent-ding.git
cd agent-ding
./setup.sh                 # interview on a real terminal
# or non-interactive:
./install.sh --only notify --with-hooks
./uninstall.sh
./uninstall.sh --purge
```

```bash
agent-ding claude
agent-ding grok "fixed the flaky test"
```

## Multi-support (not one stack)

Works with **whatever you already use**:

| Piece | Role | Required? |
|-------|------|-----------|
| Ghostty / iTerm / Terminal / WezTerm / kitty / … | Terminal host | Use any |
| Zellij (or plain splits) | Multi-pane | Optional |
| Claude / Grok / Agy / Codex | Coding agents | Optional hooks |
| terminal-notifier (macOS) | Brand toast icons | `brew install terminal-notifier` |

| Package | Standalone | Purpose |
|---------|------------|---------|
| **notify** | ✅ | `agent-ding` CLI + icons |
| **layouts** | ✅ | Sample Zellij KDL — [DIY](packages/layouts/DIY.md) |
| **shell** | ✅ | Optional `ai` / `groks` |
| **ghostty** | ✅ | Optional config snippet |

Optional: [zellij-attention](https://github.com/KiryuuLight/zellij-attention) for tab ✅.

## Install flags

```bash
./install.sh --only notify
./install.sh --only layouts
./install.sh --only notify --with-hooks
./install.sh --only notify --with-zellij-attention
./install.sh --all
```

State: `~/.local/share/agent-ding/install-state.json` → used by uninstall.

## Hooks (done-only)

Prefer **absolute path** (agent hook PATH often lacks `~/.local/bin`):

```json
"command": "/Users/YOU/.local/bin/agent-ding claude"
```

Claude: `Stop` only. Grok: `turn_complete` / `task_complete` only.  
`./install.sh --with-hooks` writes absolute paths when configs exist.

## DIY panes

Sample layouts are templates. Edit freely or skip layouts and only install notify.  
See [packages/layouts/DIY.md](packages/layouts/DIY.md).

## Click-to-focus

Toast click brings the **terminal app** forward. Exact Zellij pane focus is not reliable; use tab marks if needed.

## Uninstall (no junk)

```bash
./uninstall.sh
./uninstall.sh --dry-run
./uninstall.sh --purge
```

## License

MIT. Brand marks identify local notification senders only; trademarks stay with their owners.

## Contributing

[CONTRIBUTING.md](./CONTRIBUTING.md)
