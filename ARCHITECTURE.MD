# Architecture

## System Overview

Ohmyword is a Phoenix 1.8+ LiveView application for learning Serbian. It combines a rule-based linguistic inflection engine with a two-layer data architecture (source of truth + search cache) and interactive exercise modes.

**Tech Stack**: Elixir 1.15+, Phoenix LiveView, PostgreSQL, Tailwind CSS + DaisyUI, esbuild, Fly.io

---

## Application Structure

```
lib/
├── ohmyword/                      # Core business logic (OTP app: Ohmyword)
│   ├── accounts/                  # User auth context (Scope, User, UserToken)
│   ├── vocabulary/                # Word management context
│   │   ├── word.ex                # Word schema
│   │   ├── word_importer.ex       # Seed import logic
│   │   ├── metadata.ex            # Base metadata struct
│   │   └── metadata/              # POS-specific metadata (noun, verb, adj, etc.)
│   ├── search/                    # Search context (SearchTerm schema + queries)
│   ├── exercises/                 # Sentence exercises context
│   │   ├── sentence.ex            # Sentence schema
│   │   └── sentence_word.ex       # Join table schema
│   ├── linguistics/               # Inflection engine
│   │   ├── dispatcher.ex          # Routes words to inflectors by POS
│   │   ├── inflector.ex           # Behaviour definition
│   │   ├── cache_manager.ex       # Syncs engine output → search_terms table
│   │   ├── validator.ex           # Validates engine vs seed forms
│   │   ├── sound_changes.ex       # Phonological transformations
│   │   ├── helpers.ex             # Shared utilities (fleeting_a, overrides)
│   │   ├── nouns.ex               # 5 declension classes, 14 forms
│   │   ├── verbs.ex               # 4 conjugation classes, up to 24 forms
│   │   ├── adjectives.ex          # Indef/def/comp/super, up to 168 forms
│   │   ├── pronouns.ex            # Personal/possessive/demonstrative/etc.
│   │   ├── numerals.ex            # Cardinal/ordinal/collective
│   │   ├── invariables.ex         # Adverbs, prepositions, conjunctions, etc.
│   │   └── stub_inflector.ex      # Fallback for unknown POS
│   ├── utils/
│   │   └── transliteration.ex     # Latin↔Cyrillic + diacritic stripping
│   └── policy/                    # Authorization (admin checks)
│
├── ohmyword_web/                  # Web interface (OTP app: OhmywordWeb)
│   ├── router.ex                  # Route definitions
│   ├── user_auth.ex               # Auth plugs and LiveView on_mount hooks
│   ├── live/
│   │   ├── dictionary_live.ex     # Word search with inflection display
│   │   ├── flashcard_live.ex      # Flashcard practice (flip + write modes)
│   │   ├── word_detail_live.ex    # Full inflection tables for a word
│   │   ├── write_sentence_live.ex # Multi-blank sentence exercises
│   │   ├── admin_dashboard_live.ex
│   │   └── user_live/             # Auth pages (login, register, settings, etc.)
│   ├── components/
│   │   ├── core_components.ex     # Buttons, forms, flash, containers
│   │   ├── word_components.ex     # POS/gender/aspect badges, script toggle, filters
│   │   ├── inflection_table_components.ex  # Noun/verb/adjective/generic tables
│   │   └── layouts.ex             # Root and app layouts
│   ├── controllers/               # PageController, UserSessionController
│   └── plugs/                     # AppInfo, RequireAdmin
```

---

## Data Flow

### Search Flow
```
User types query (any script, any form)
  → to_latin() → strip_diacritics() → downcase()
  → Match against search_terms.term (ASCII)
  → Return display_form (with diacritics) + word metadata
  → Render in user's chosen script (Latin or Cyrillic)
```

### Inflection Generation Flow
```
Word created/updated in vocabulary_words
  → CacheManager.regenerate_word()
  → Dispatcher.inflect(word)
    → Routes to POS inflector (Nouns/Verbs/Adjectives/etc.)
    → Returns [{form_string, form_tag}, ...]
  → For each form:
    - term = strip_diacritics(form) |> downcase()
    - display_form = downcase(form)
  → Upsert into search_terms (source: :engine, locked: false)
  → Locked seed entries are preserved
```

### Sentence Exercise Flow
```
Get random sentence (optionally filtered by POS)
  → Tokenize text_rs with [\p{L}]+ regex
  → Select blanks based on difficulty (1=one, 2=half, 3=all annotated)
  → User fills blanks
  → Check each answer:
    - Normalize input (to_latin + strip_diacritics + downcase)
    - Query search_terms for all display_forms matching word_id + form_tag
    - Compare normalized input against normalized expected forms
```

---

## Database Schema

### Tables

| Table | Purpose | Key columns |
|-------|---------|-------------|
| `users` | Authentication | email (citext), hashed_password, role, confirmed_at |
| `users_tokens` | Sessions & email tokens | token (binary), context, authenticated_at |
| `vocabulary_words` | Dictionary entries | term, translation, part_of_speech, gender, grammar_metadata |
| `search_terms` | Inflected form cache | term (ASCII), display_form (diacritics), form_tag, word_id, source, locked |
| `sentences` | Sentence bank | text_rs, text_en |
| `sentence_words` | Word-position mapping | position, form_tag, sentence_id, word_id |

### Key Indexes
- `search_terms.term` — B-tree for fast prefix/exact lookups
- `(term, word_id, form_tag)` — Unique constraint on search_terms
- `(sentence_id, position)` — Unique constraint on sentence_words
- `vocabulary_words.categories` — GIN index for array containment queries

---

## Linguistics Engine

### Dispatcher Pattern
Each inflector implements the `Inflector` behaviour (`applicable?/1` + `generate_forms/1`). The Dispatcher tries them in order: Nouns → Verbs → Adjectives → Pronouns → Numerals → Invariables → StubInflector.

### Inflector Summary

| Module | Applies to | Forms generated | Key features |
|--------|-----------|----------------|--------------|
| Nouns | noun | 14 (7 cases x 2 numbers) | 5 declension classes, fleeting_a, palatalization, sibilarization, plural insert, drops_in_plural, animacy |
| Verbs | verb | 18-24 | 4 conjugation classes + irregular, present/L-participle/imperative/passive participle/adverbial participles |
| Adjectives | adjective | Up to 168+ | Indefinite/definite/comparative/superlative, soft-stem detection, fleeting_a |
| Pronouns | pronoun | Varies | Personal/possessive/demonstrative/interrogative/relative/indefinite/negative, mostly hardcoded paradigms |
| Numerals | numeral | Varies | Cardinal (1-4 declined, 5+ invariable), ordinal (adjective-like), collective |
| Invariables | adverb, preposition, conjunction, interjection, particle | 1-3 | Base form, optional comparative/superlative for adverbs |

### Sound Changes (`sound_changes.ex`)
- **Palatalization**: k→c, g→z, h→s (vocative)
- **Sibilarization**: k→c, g→z, h→s (dat/loc singular a-stem)
- **Iotation**: consonant+j → soft consonant (passive participles, je-verb stems)
- **Voice assimilation**: Voiced→voiceless before voiceless consonants
- **L-O alternation**: Reverses historical l→o change (beo→bel)

### Irregular Forms
Stored in `grammar_metadata.irregular_forms` as a map of `form_tag → form_string`. Applied via `Helpers.apply_overrides/2` after regular generation.

---

## Authentication

Scope-based system where `Ohmyword.Accounts.Scope` wraps the user struct:

- Router pipeline assigns `:current_scope` to conn
- LiveView `on_mount` hooks: `:mount_current_scope`, `:require_authenticated`, `:require_sudo_mode`, `:require_admin_user`
- Token-based sessions stored in `users_tokens` table
- Remember-me cookie: 14 days, session reissue every 7 days
- Email confirmation required before login

---

## Routes

| Path | Handler | Auth | Purpose |
|------|---------|------|---------|
| `/` | PageController | Public | Landing page |
| `/flashcards` | FlashcardLive | Public | Flashcard practice |
| `/dictionary` | DictionaryLive | Public | Word search |
| `/dictionary/:id` | WordDetailLive | Public | Word detail + inflection tables |
| `/write` | WriteSentenceLive | Public | Sentence exercises |
| `/admin/kaffy` | Kaffy | Admin | Admin dashboard |
| `/users/*` | UserLive.* | Various | Auth pages (login, register, settings, etc.) |

---

## Frontend

- **Tailwind CSS 4.1.7** with **DaisyUI** component library
- **esbuild 0.25.4** for JavaScript bundling
- **Heroicons v2.2.0** for SVG icons
- **Phoenix LiveView** for all interactive pages (minimal traditional controllers)
- **Script toggle hook** for Latin↔Cyrillic switching (persisted in session)

---

## Deployment

- **Platform**: Fly.io (app name: `stasta`, domain: `stasta.world`, region: `iad`)
- **Container**: Multi-stage Docker build (Elixir 1.17.3 / OTP 27.1.2 / Debian Bookworm)
- **Server**: Bandit (not Cowboy)
- **Release command**: `/app/bin/migrate` runs before each deploy
- **Scaling**: Auto-stop/start machines, can scale to zero
- **CI/CD**: GitHub Actions — CI on PR, CD triggered by version tags (`v*`) on main

---

## Testing

- **1486 tests** covering all layers
- **Inflector validation test** runs all 1022 seed words through the engine and compares output
- **SQL Sandbox** for database isolation, async-safe
- **Fixtures** in `test/support/fixtures/` for accounts, vocabulary, exercises
- **`mix precommit`** must be run before every commit (compile, format, test)
