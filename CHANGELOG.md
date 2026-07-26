# Changelog

All notable changes to this project will be documented in this file.

## [0.1.2] — 2026-07-26

### Fixed

- **Wrong brand on Grok:** host detection now reads `GROK_AGENT`, `GROK_WORKSPACE_ROOT`, `GROK_HOOK_*`, and walks up to 12 parent processes. If the hook arg says `claude` but the host is Grok, remap to **Grok** (no more Claude Code toast inside Grok). Reverse remap for Claude host + `grok` arg.
- **Double icon on macOS:** stop passing `-contentImage` / redundant `-appIcon` when `-sender` is set (right-side duplicate tile).
- Collapse double-fire (Claude-compat Stop + Grok Stop) via a shared notification `-group` per project.

## [0.1.1] — 2026-07-26

### Fixed

- **Grok hooks:** install `~/.grok/hooks/agent-ding.json` (`Stop` → `agent-ding grok`) instead of relying on `[ui.notifications] method = "none"`, which on Grok Build 0.2.x disables the whole notification pipeline so dings never fire
- Strip legacy `>>> agent-ding grok <<<` `ui.notifications` blocks on reinstall; uninstall removes the Grok hooks file

### Docs

- Document Claude / Grok / Codex / Agy wiring and the `method = "none"` footgun

## [0.1.0] — 2026-07-26

### Added

- Modular packages: `notify`, `layouts`, `shell`, `ghostty`
- `agent-ding` CLI — done-only desktop notifications with brand icons (macOS)
- Zellij layouts: `ai-workspace`, `groks-workspace`
- Shell helpers: `ai` / `groks`
- Installer: `./install.sh` with `--only` / `--all` / `--with-hooks` / `--with-zellij-attention`
