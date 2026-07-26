# DIY layouts

Sample layouts are **starting points**, not required.

## Where they live

After install: `~/.config/zellij/layouts/`

- `ai-workspace.kdl` — multi-agent row + shell tab
- `groks-workspace.kdl` — two Grok panes + shell
- `default.kdl` — single pane

## Minimal custom layout

```kdl
layout {
    tab name="agents" focus=true {
        pane split_direction="vertical" {
            pane name="My Claude" command="claude" close_on_exit=false
            pane name="My Grok" command="grok" close_on_exit=false
            // add/remove panes freely
        }
    }
    tab name="shell" {
        pane
    }
}
```

## Tips

| Goal | How |
|------|-----|
| Re-run agent after exit | `close_on_exit=false` then press **Enter** |
| Pass flags | `args "--flag" "value"` inside the pane block |
| No sample layouts | Skip `layouts` package; only install `notify` |
| Launch | `zellij --layout my-layout` or set `default_layout` |

Notifications work in **any** pane that runs an agent with hooks — layout is independent of dinging.
