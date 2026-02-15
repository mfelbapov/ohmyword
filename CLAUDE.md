# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

For full details, see:
- **[ARCHITECTURE.MD](ARCHITECTURE.MD)** — System design, module structure, data flow, database schema
- **[DECISIONS.MD](DECISIONS.MD)** — Key design decisions with rationale
- **[MASTER_PROMPT.md](MASTER_PROMPT.md)** — Original project specification and schema definitions

---

## Project Overview

Ohmyword is a Serbian vocabulary learning app built with Phoenix 1.8+, LiveView, Elixir 1.15+, and PostgreSQL. It features a rule-based inflection engine that generates all grammatical forms of Serbian words, a two-table data architecture (source of truth + search cache), and interactive exercises (flashcards, dictionary search, sentence fill-in-the-blank).

**Current state**: 1022 vocabulary words, sentence bank with multi-blank exercises, full inflection engine covering nouns, verbs, adjectives, pronouns, numerals, and invariables.

---

## Development Commands

```bash
mix setup                # Full setup: deps.get, ecto.setup, assets.setup, assets.build
mix phx.server           # Start server (localhost:4000)
iex -S mix phx.server    # Start server with interactive shell

mix ecto.reset           # Drop and recreate database (re-seeds)
mix ecto.migrate         # Run pending migrations

mix test                 # Run all tests (1486 tests)
mix test path/to/test.exs        # Run single file
mix test path/to/test.exs:123    # Run test at line

mix format               # Format code
mix compile --warnings-as-errors
mix precommit            # REQUIRED before every commit: compile + deps.unlock + format + test
```

**IMPORTANT: Always run `mix precommit` before every commit.** Skipping this causes CI failures.

---

## Key Conventions

### Code Organization
- **Contexts**: `Accounts`, `Vocabulary`, `Search`, `Exercises` — business logic in `lib/ohmyword/`
- **Linguistics engine**: `lib/ohmyword/linguistics/` — Dispatcher routes to POS-specific inflectors
- **LiveViews**: `lib/ohmyword_web/live/` — DictionaryLive, FlashcardLive, WordDetailLive, WriteSentenceLive
- **Components**: `lib/ohmyword_web/components/` — core_components, word_components, inflection_table_components

### Data Patterns
- **Dual-form storage**: `search_terms.term` (ASCII, for matching) + `search_terms.display_form` (diacritics, for display)
- **Diacritics stripped only at storage**: `Utils.Transliteration.strip_diacritics/1` in CacheManager and seeds, NOT in Dispatcher
- **Irregular forms**: Stored in `grammar_metadata.irregular_forms` map (form_tag → form string), applied via `Helpers.apply_overrides/2`
- **Seed data**: `priv/repo/vocabulary_seed.json` (words) + `priv/repo/sentences_seed.json` (sentences)

### Authentication
- Scope-based: `Ohmyword.Accounts.Scope` wraps user, assigned as `:current_scope`
- LiveView hooks: `:mount_current_scope`, `:require_authenticated`, `:require_admin_user`
- Email confirmation required before login

### Testing
- Fixtures in `test/support/fixtures/` (AccountsFixtures, VocabularyFixtures, ExercisesFixtures)
- Use `setup :register_and_log_in_user` for authenticated test context
- SQL Sandbox for isolation, `async: true` safe
- Inflector validation test validates all 1022 seed words against the engine

---

## Serbian Language Standard

This application uses **Serbian ekavski** exclusively. When working with vocabulary:

- **Ekavski only**: Use ekavski jat reflex (e), never ijekavski (ije/je). E.g., "mleko" not "mlijeko", "dete" not "dijete", "reka" not "rijeka", "lepo" not "lijepo".
- **Serbian lexicon**: Use standard Serbian vocabulary, not Croatian, Bosnian, or Montenegrin variants. E.g., "so" not "sol", "sto" not "stol", "hleb" not "kruh", "voz" not "vlak", "vazduh" not "zrak", "hiljada" not "tisuća", "pozorište" not "kazalište".
- These constraints apply to both base terms AND all inflected forms.

---

## Deployment Rules

- NEVER push directly to `main`. Always create a feature branch and open a PR.
- NEVER create or push version tags (e.g., v1.x.x) unless I explicitly ask you to.
- NEVER run `git push` to any remote without asking me first.
- Default workflow: create a branch → commit → push branch → open PR.

## CI/CD

- Pushing a version tag (`v*`) to main triggers production deployment via Fly.io.
- Tags must ONLY be created manually by me. Never create or push tags.
- Merging a PR to main does NOT deploy — only tags do.
