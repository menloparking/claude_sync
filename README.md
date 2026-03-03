# claude_sync

A development gem that syncs your project's `CLAUDE.md` file from a GitHub Gist. Keeps your Claude
Code instructions consistent across dev containers, Codespaces, and local environments.

## Features

- **Auto-sync on Rails boot** in development and test environments
- **24-hour freshness window** to avoid excessive API calls (configurable)
- **ETag caching** for conditional HTTP requests
- **Silent skip** when `CLAUDE_SYNC_GIST_URL` is not set
- **Never crashes** — all errors are caught gracefully
- **Zero runtime dependencies** — uses only Ruby stdlib

## Installation

Add to your Gemfile's development group:

```ruby
group :development, :test do
  gem "claude_sync"
end
```

Then run `bundle install`.

## Configuration

Set environment variables (in the shell, `.env.development`, or `.env`):

| Variable               | Required | Default      | Description                       |
| ---------------------- | -------- | ------------ | --------------------------------- |
| `CLAUDE_SYNC_GIST_URL` | Yes      | —            | Full URL to your GitHub Gist      |
| `CLAUDE_SYNC_FILE`     | No       | `CLAUDE.md`  | Target filename to write          |
| `CLAUDE_SYNC_INTERVAL` | No       | `86400` (24h)| Freshness interval in seconds     |
| `CLAUDE_SYNC_QUIET`    | No       | `0`          | Set to `1` to suppress output     |
| `GITHUB_TOKEN`         | No       | —            | Auth token for private gists      |

Variables are resolved in this order: active environment, then `.env.development`, then `.env`. No
external dependencies are needed — the gem parses dotenv files itself.

## Usage

### Rails

With the gem in your Gemfile, it automatically syncs on boot in development and test environments.
No additional setup required.

### Rake Tasks

```sh
rake claude_sync:fetch        # Fetch (respects freshness)
rake claude_sync:force_fetch  # Fetch regardless of freshness
rake claude_sync:status       # Show current sync state
```

### CLI

```sh
claude-sync          # Fetch (respects freshness)
claude-sync force    # Force fetch
claude-sync status   # Show status
```

### Ruby API

```ruby
require "claude_sync"

syncer = ClaudeSync::Syncer.new
result = syncer.sync  # => :ok, :fresh, :not_modified, :skipped, or :error

syncer = ClaudeSync::Syncer.new(force: true)
result = syncer.sync  # Bypasses freshness check
```

## How It Works

1. Checks if `CLAUDE_SYNC_GIST_URL` is set — silently skips if not
2. Checks freshness — skips if synced within the interval
3. Fetches gist via GitHub API with ETag conditional request
4. Writes the first file's content to `CLAUDE.md` (or configured name)
5. Saves metadata (ETag, timestamp) to `.claude_sync_metadata.json`
6. Ensures both files are in `.gitignore`

## Development

```sh
bundle install
bundle exec rake test
bundle exec standardrb
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
