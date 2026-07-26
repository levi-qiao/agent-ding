# Contributing

Thanks for helping improve **agent-ding**.

## Principles

1. **Modular** — changes to `notify` must not require `layouts`, and vice versa.
2. **Done-only by default** — do not reintroduce permission/idle spam without a clear opt-in.
3. **Honest docs** — document limitations (click-to-pane, platform quirks).
4. **No vendored secrets** — no API keys, no personal paths hard-coded in hooks.

## Dev setup

```bash
./install.sh --only notify
agent-ding claude   # smoke test (macOS)
```

## Pull requests

- Keep diffs focused; one concern per PR when possible.
- Update README / `docs/` if behavior changes.
- Prefer env vars over new config file formats unless necessary.
- Shell scripts: `bash`, `set -euo pipefail`, no bashisms that break macOS `/bin/bash` 3.2 when avoidable (prefer `#!/usr/bin/env bash` features carefully).

## Code of conduct

Be respectful. No harassment. Assume good intent. Maintainers may close hostile or off-topic issues.
