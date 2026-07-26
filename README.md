# agent-ding

**Ding when your coding agent finishes.**

English-only, **done-only** desktop toasts (not permission spam). Works in **any terminal**; optional Zellij layouts are DIY templates. Modular — install only what you want. Clean uninstall.

```text
agent turn completes  →  agent-ding claude|grok|agy|codex  →  toast “project · Done”
```

## For humans

```bash
git clone https://github.com/levi-qiao/agent-ding.git
cd agent-ding
./setup.sh          # interview: detects your machine, asks, installs
# or
./install.sh        # defaults: notify + sample layouts
./uninstall.sh      # remove what we installed
./uninstall.sh --purge
```

```bash
agent-ding claude
agent-ding grok "fixed the flaky test"
```

## For coding agents

Give your agent this URL and ask it to set up agent-ding:

**https://github.com/levi-qiao/agent-ding/blob/main/docs/for-agents.md**

The agent should **detect installed tools**, **interview you**, and only configure packages you accept (DIY panes, done-only hooks, no leftover junk).

## What you might already have

agent-ding does **not** force one stack. Multi-support:

| You run… | Role | Install |
|----------|------|---------|
| **Any terminal** (Ghostty, iTerm, Terminal.app, WezTerm, kitty, …) | Host UI | Optional; use what you have |
| **Zellij** (or plain splits) | Multi-agent panes/tabs | Optional |
| **Claude / Grok / Agy / Codex** | Coding agents | Optional hooks (done-only) |
| **terminal-notifier** (macOS) | Branded toast icons | `brew install terminal-notifier` |

| Package | Standalone | Purpose |
|---------|------------|---------|
| **notify** | ✅ | `agent-ding` CLI + brand icons |
| **layouts** | ✅ | Sample Zellij KDL (**edit freely** — see [DIY](packages/layouts/DIY.md)) |
| **shell** | ✅ | Optional `ai` / `groks` helpers |
| **ghostty** | ✅ | Optional config snippet |

Optional: [zellij-attention](https://github.com/KiryuuLight/zellij-attention) for tab ✅ marks.

## Install options

```bash
./install.sh --only notify
./install.sh --only layouts
./install.sh --all --with-hooks --with-zellij-attention
./setup.sh                         # recommended interactive path
```

State is recorded in `~/.local/share/agent-ding/install-state.json` so **uninstall** can reverse bins, layouts, shell markers, snippets, and hooks we added.

## Wire agents (done-only)

**Claude** — `Stop` only:

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [{ "type": "command", "command": "agent-ding claude" }] }
    ]
  }
}
```

**Grok** — see `hooks/grok.config.fragment.toml` (`turn_complete` / `task_complete` only).

Keep unrelated hooks (e.g. rtk). Do not enable permission/idle dings unless you choose to.

## DIY panes

Sample layouts are **templates**, not a product lock-in:

- Edit `~/.config/zellij/layouts/*.kdl` or copy from `packages/layouts/`
- Add/remove agent panes as you like
- `close_on_exit=false` → pane stays; **Enter** re-runs the command
- **Notify works without any sample layout** if hooks call `agent-ding`

## Click-to-focus

| Behavior | Status |
|----------|--------|
| Click toast → bring terminal **app** forward | Yes |
| Click toast → exact Zellij **tab/pane** | Not reliable; use tab ✅ marks instead |

## Env (optional)

| Variable | Default | Meaning |
|----------|---------|---------|
| `AGENT_DING_MSG_DONE` | `Done` | Body when no custom message |
| `AGENT_DING_SOUND` | per client | macOS sound |
| `AGENT_DING_ACTIVATE` | from `TERM_PROGRAM` | Bundle id to activate |
| `AGENT_DING_ZELLIJ_MARK` | `1` | Pipe completed mark |
| `AGENT_DING_BELL` | `1` | Terminal BEL |

## Uninstall (no garbage)

```bash
./uninstall.sh           # reverse tracked install
./uninstall.sh --dry-run
./uninstall.sh --purge   # also delete icons/apps data dir
```

Removes: binaries we installed, layouts we copied, shell/ghostty blocks we marked, zellij-attention wasm if we installed it, Claude/Grok hook fragments we added.

## License

MIT — [LICENSE](./LICENSE). Brand marks used only to identify local notification senders; trademarks remain with their owners.

## Contributing

[CONTRIBUTING.md](./CONTRIBUTING.md)
