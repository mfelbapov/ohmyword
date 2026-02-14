# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ohmyword is a Phoenix 1.8+ web application built with Elixir 1.15+. It's a ohmywordplate/starter project with authentication functionality built-in using Phoenix LiveView and PostgreSQL.

## Development Commands

### Initial Setup
```bash
mix setup
```
This runs: deps.get, ecto.setup, assets.setup, and assets.build

### Database
```bash
mix ecto.create          # Create database
mix ecto.migrate         # Run migrations
mix ecto.reset           # Drop and recreate database
mix ecto.setup           # Create, migrate, and seed
```

### Running the Application
```bash
mix phx.server           # Start server (default port 4000)
iex -S mix phx.server    # Start server with interactive shell
```

### Testing
```bash
mix test                 # Run all tests (auto-creates test DB and runs migrations)
mix test test/path/to/test.exs               # Run a single test file
mix test test/path/to/test.exs:123           # Run test at specific line
```

### Code Quality
```bash
mix format               # Format code
mix compile --warnings-as-errors
mix precommit            # Run full pre-commit suite (compile, deps.unlock --unused, format, test)
```

**IMPORTANT: Always run `mix precommit` before every commit.** This catches formatting, compilation warnings, and test failures before they reach CI.

### Assets
```bash
mix assets.setup         # Install esbuild and tailwind
mix assets.build         # Compile assets (tailwind + esbuild)
mix assets.deploy        # Build minified assets for production
```

## Architecture

### Application Structure

The application follows Phoenix conventions with two main OTP applications:
- `Ohmyword` - Core business logic (contexts, schemas, repo)
- `OhmywordWeb` - Web interface (controllers, LiveViews, components, router)

### Authentication & Authorization

The app uses a custom scope-based authentication system:

**Scope Pattern**: Instead of directly passing user structs, the app uses `Ohmyword.Accounts.Scope` (lib/ohmyword/accounts/scope.ex:1) which wraps user information. This allows for:
- Logging and audit trails
- PubSub subscription scoping
- Future extensibility for permissions/privileges

**Key modules**:
- `OhmywordWeb.UserAuth` (lib/ohmyword_web/user_auth.ex:1) - Plugs and helpers for authentication
- `Ohmyword.Accounts` (lib/ohmyword/accounts.ex:1) - User management context
- `Ohmyword.Accounts.User` - User schema
- `Ohmyword.Accounts.UserToken` - Session/email confirmation tokens

**Authentication flow**:
1. Router pipeline `:browser` includes `fetch_current_scope_for_user` plug (lib/ohmyword_web/router.ex:13)
2. This assigns `:current_scope` to conn, containing wrapped user or nil
3. Protected routes use `:require_authenticated_user` pipeline (lib/ohmyword_web/router.ex:51)
4. LiveView routes use `on_mount: [{OhmywordWeb.UserAuth, :require_authenticated}]` (lib/ohmyword_web/router.ex:54)

**Scope configuration**: Defined in config/config.exs:10-21 with metadata about how scopes map to schemas.

### LiveView Structure

All user-facing auth pages are LiveViews in `lib/ohmyword_web/live/user_live/`:
- `Login` - User login
- `Registration` - User registration
- `Settings` - User settings (email, password)
- `Confirmation` - Email confirmation
- `ResendConfirmation` - Resend confirmation email

### Database

- **ORM**: Ecto with PostgreSQL
- **Connection pooling**: Configured in config files
- **Migrations**: Located in priv/repo/migrations/
- **Primary schema**: users table with citext email extension for case-insensitive emails

### Frontend

- **CSS**: Tailwind CSS 4.1.7 (configured in config/config.exs:58-66)
- **JS Bundler**: esbuild 0.25.4 (configured in config/config.exs:47-55)
- **Components**: lib/ohmyword_web/components/
  - `core_components.ex` - Reusable UI components
  - `layouts.ex` - Layout components
- **Icons**: Heroicons v2.2.0 (SVG icons)

### Testing Infrastructure

- **Test helpers**: test/support/ contains ConnCase and DataCase
- **Fixtures**: Test data generation via `Ohmyword.AccountsFixtures`
- **Test setup**: Use `setup :register_and_log_in_user` to create authenticated test context
- **SQL Sandbox**: Enabled for database isolation between tests
- **Async tests**: Safe for PostgreSQL with `use OhmywordWeb.ConnCase, async: true`

## Configuration Notes

### Environments

- **Development**: config/dev.exs - Live reload enabled, port 4000
- **Test**: config/test.exs - SQL Sandbox, fast bcrypt (log_rounds: 1)
- **Production**: config/runtime.exs - Runtime configuration from environment variables

### Session Management

- Remember-me cookie: 14 days validity
- Session reissue: Every 7 days for active users
- Cookie name: `_ohmyword_web_user_remember_me`

## Deployment

The project includes:
- Dockerfile for containerized deployments
- fly.toml for Fly.io deployment
- Release configuration in lib/ohmyword/release.ex

## Deployment Rules
- NEVER push directly to `main`. Always create a feature branch and open a PR.
- NEVER create or push version tags (e.g., v1.x.x) unless I explicitly ask you to.
- NEVER run `git push` to any remote without asking me first.
- Default workflow: create a branch → commit → push branch → open PR.


## CI/CD
- Pushing a version tag (v*) to main triggers a production deployment.
- Tags must ONLY be created manually by me. Never create or push tags.
- Merging a PR to main does NOT deploy — only tags do.

## Important Implementation Details

1. **User confirmation required**: Users must confirm email before logging in (see Ohmyword.Accounts.get_user_by_email_and_password)
2. **Token-based sessions**: Uses database-backed tokens (users_tokens table) for session management
3. **Live socket disconnection**: On logout, broadcasts disconnect to user's live socket
4. **Asset compilation**: Custom compilers configuration in mix.exs:13 includes phoenix_live_view compiler
5. **Password hashing**: bcrypt_elixir with configurable rounds (1 for test, default for prod)

## Serbian Language Standard

This application uses **Serbian ekavski** as its language standard. When working with vocabulary:

- **Ekavski only**: Use ekavski jat reflex (e), never ijekavski (ije/je). E.g., "mleko" not "mlijeko", "dete" not "dijete", "reka" not "rijeka", "lepo" not "lijepo".
- **Serbian lexicon**: Use standard Serbian vocabulary, not Croatian, Bosnian, or Montenegrin variants. E.g., "so" not "sol", "sto" not "stol", "hleb" not "kruh", "voz" not "vlak", "vazduh" not "zrak", "hiljada" not "tisuća", "pozorište" not "kazalište".
- These constraints apply to both base terms AND all inflected forms.
