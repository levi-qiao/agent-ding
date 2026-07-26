# Changelog

All notable changes to this project will be documented in this file.

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
