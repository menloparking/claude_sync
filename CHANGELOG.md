# Changelog

## 0.1.0 (2026-02-28)

- Initial release
- Sync `claude.md` from a GitHub Gist via environment variable
- ETag conditional requests to minimize API usage
- 24-hour freshness window (configurable via `CLAUDE_SYNC_INTERVAL`)
- Rails Railtie for auto-sync on boot in development/test
- Rake tasks: `claude_sync:sync`, `force_sync`, `status`
- CLI executable: `claude-sync`
- Automatic `.gitignore` management
- Support for private gists via `GITHUB_TOKEN`
