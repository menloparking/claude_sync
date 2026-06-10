# claude_sync

A development gem that syncs your project's agent instruction files from a GitHub Gist or Drive.
Keeps `CLAUDE.md` and `AGENTS.md` consistent across dev containers, Codespaces, and local
environments.

## Features

- **Auto-sync on Rails boot** in development and test environments
- **24-hour freshness window** to avoid excessive API calls (configurable)
- **ETag caching** for conditional HTTP requests
- **Silent skip** when no source is configured
- **Drive document support** for `drive.menloparking.com`
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

| Variable                              | Required | Default                    | Description                                  |
| ------------------------------------- | -------- | -------------------------- | -------------------------------------------- |
| `CLAUDE_SYNC_GIST_URL`                | No       | —                          | Full URL to your GitHub Gist                 |
| `CLAUDE_SYNC_DRIVE_DOCUMENT_ID`       | No       | —                          | Drive document ID/URL for `CLAUDE.md`        |
| `CLAUDE_SYNC_AGENTS_DRIVE_DOCUMENT_ID` | No       | —                          | Drive document ID/URL for `AGENTS.md`        |
| `CLAUDE_SYNC_DRIVE_DOCUMENT_IDS`      | No       | —                          | `file:id` pairs, comma-separated             |
| `CLAUDE_SYNC_FILE`                    | No       | `CLAUDE.md`                | Single target filename to write              |
| `CLAUDE_SYNC_FILES`                   | No       | `CLAUDE.md,AGENTS.md`      | Target filenames, comma-separated            |
| `CLAUDE_SYNC_INTERVAL`                | No       | `86400` (24h)              | Freshness interval in seconds                |
| `CLAUDE_SYNC_QUIET`                   | No       | `0`                        | Set to `1` to suppress output                |
| `CLAUDE_SYNC_DRIVE_TOKEN`             | No       | —                          | Auth token for Drive documents               |
| `DRIVE_MENLOPARKING_TOKEN`            | No       | —                          | Fallback auth token for Drive documents      |
| `GITHUB_TOKEN`                        | No       | —                          | Auth token for private gists                 |

Set either a GitHub Gist source or one or more Drive document sources.

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

1. Checks if a GitHub Gist or Drive source is configured — silently skips if not
2. Checks freshness — skips if synced within the interval
3. Fetches GitHub Gist JSON or Drive document text with conditional request headers
4. Writes matched content to `CLAUDE.md`, `AGENTS.md`, or configured filenames
5. Saves metadata (ETag, timestamp) to `.claude_sync_metadata.json`
6. Ensures both files are in `.gitignore`

For Drive, the gem requests `Accept: text/plain` from the document endpoint:

```text
https://drive.menloparking.com/api/v1/documents/<document-id>
```

## Development

```sh
bundle install
bundle exec rake test
bundle exec standardrb
```

## License

MIT License. See [LICENSE.txt](LICENSE.txt).
