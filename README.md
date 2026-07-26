# agent-ding

**Ding when your coding agent finishes** — modular toolkit for multi-agent terminals.

macOS desktop toasts with **per-client brand icons**, optional **Zellij layouts**, and shell helpers. Each package installs on its own.

```
agent finishes (Stop / turn_complete)
        │
        ▼
   agent-ding claude|grok|agy|codex
        │
        ├── branded macOS toast (2 lines)
        ├── click → bring terminal app forward
        └── optional Zellij tab ✅ (zellij-attention)
```

## Why

Coding agents often finish while you’re in another window. Terminal OSC notifications break inside multiplexers (Zellij/tmux). **agent-ding** only fires on **turn complete**, not every permission prompt.

## Packages (pick what you need)

| Package | Path | Standalone? | What you get |
|---------|------|-------------|--------------|
| **notify** | `packages/notify` | ✅ | `agent-ding` CLI + icon apps |
| **layouts** | `packages/layouts` | ✅ | Zellij `ai-workspace` / `groks-workspace` |
| **shell** | `packages/shell` | ✅ | `ai` / `groks` functions |
| **ghostty** | `packages/ghostty` | ✅ | recommended Ghostty snippet |

Optional third-party: [zellij-attention](https://github.com/KiryuuLight/zellij-attention) for tab marks.

## Quick install

```bash
git clone https://github.com/levi-qiao/agent-ding.git
cd agent-ding
./install.sh                 # notify + layouts
# or
./install.sh --all --with-hooks --with-zellij-attention
```

```bash
./install.sh --only notify   # just the ding
./install.sh --only layouts
./install.sh --only shell    # prints how to source helpers
```

**macOS deps:** `brew install terminal-notifier` (icons use a branded copy of its `.app`).

### Wire agents (done-only)

**Claude Code** — `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      { "hooks": [{ "type": "command", "command": "agent-ding claude" }] }
    ]
  }
}
```

**Grok** — append `hooks/grok.config.fragment.toml` to `~/.grok/config.toml`.

**Manual test:**

```bash
agent-ding claude
agent-ding grok "fixed the flaky test"
```

## Click-to-focus: what works

| Level | Status | Notes |
|-------|--------|--------|
| Bring **terminal app** forward | ✅ | `-activate` Ghostty / iTerm / Terminal |
| Exact **Zellij tab/pane** | ⚠️ | Not reliable from notification click; use **zellij-attention** ✅ marks instead |
| Window-level focus | ⚠️ | OS-dependent |

Honest takeaway: **app focus + tab marks** is the practical combo. Pixel-perfect pane focus usually needs a dedicated plugin stack (e.g. Claude-only tools).

## Layouts

```bash
# after install + shell helpers
ai          # Grok | Claude | Agy + shell tab
groks       # dual Grok + shell
```

Command panes use Zellij `close_on_exit=false` (Enter re-runs).

## Configuration (env)

| Variable | Default | Meaning |
|----------|---------|---------|
| `AGENT_DING_LOCALE` | auto `en`/`zh` | Message language |
| `AGENT_DING_MSG_DONE` | `Done` / `本轮已完成` | Body when no custom text |
| `AGENT_DING_SOUND` | per-client | macOS sound name |
| `AGENT_DING_ACTIVATE` | from `TERM_PROGRAM` | Bundle id to activate |
| `AGENT_DING_ZELLIJ_MARK` | `1` | Pipe completed mark |
| `AGENT_DING_BELL` | `1` | Terminal BEL |
| `AGENT_DING_APP_DIR` | `~/.local/share/agent-ding/apps` | Brand notifier apps |

## Uninstall

```bash
rm -f ~/.local/bin/agent-ding*
rm -rf ~/.local/share/agent-ding
# remove layouts you copied under ~/.config/zellij/layouts/
# remove Stop hooks referencing agent-ding
```

## Project layout

```
packages/notify/bin/     # agent-ding, icons, build-apps
packages/layouts/        # *.kdl + zellij snippet
packages/shell/          # ai.zsh / ai.bash
packages/ghostty/        # config.snippet
hooks/                   # Claude / Grok fragments
docs/                    # design notes
install.sh
```

## Related

- We **do not** ship hellolib agent-notify (too noisy by default).
- Optional: [zellij-attention](https://github.com/KiryuuLight/zellij-attention)
- Brand marks for icons: [lobe-icons](https://github.com/lobehub/lobe-icons) + [Antigravity press](https://antigravity.google/press) (trademarks belong to their owners; used for identification only).

## License

MIT — see [LICENSE](./LICENSE).

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). Issues and PRs welcome.
