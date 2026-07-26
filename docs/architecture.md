# Architecture

## Goals

1. **Done-only signals** — fire when a coding agent turn finishes.
2. **Multiplexer-safe** — do not rely on OSC passthrough through Zellij/tmux.
3. **Modular** — install notify without layouts, layouts without notify.
4. **Identifiable** — per-client brand icon, not a generic Terminal glyph.

## Components

```
┌─────────────┐   Stop / turn_complete   ┌────────────┐
│ Claude/Grok │ ───────────────────────► │ agent-ding │
└─────────────┘                          └─────┬──────┘
                                               │
                     ┌─────────────────────────┼─────────────────────┐
                     ▼                         ▼                     ▼
              brand .app toast          optional BEL          zellij pipe ✅
              (terminal-notifier)       visual_bell           (zellij-attention)
                     │
                     ▼
              activate TERM app (Ghostty/…)
```

## Click-to-focus

macOS notifications activated via `-activate <bundle id>` only raise the **application**. Mapping a toast click to a **specific Zellij pane** requires either:

- storing `ZELLIJ_SESSION_NAME` + pane id and a custom URL handler / AppleScript (fragile), or
- a dedicated focus plugin (out of scope for v0.1).

**Recommended UX:** toast brings Ghostty forward; **zellij-attention** marks the finished tab with ✅.

## Trademark note

Icons are composed from publicly available brand assets for **user identification** of the local notification sender. Trademark rights remain with Anthropic, xAI, OpenAI, Google, etc. Downstream redistributors should review brand guidelines.
