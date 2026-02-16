# Flag the Word - Feature Design

## Problem

Users encounter incorrect inflected forms, bad translations, or problematic sentences while using the app. Currently there's no way for them to report these issues — they'd have to remember the word and tell the admin separately.

## Goal

A lightweight "flag" mechanism: user clicks a small button, optionally adds a note, and the report is saved for admin review.

---

## Decisions

- **Auth**: Login required (prevents spam, enables dedup)
- **Admin review**: Use Kaffy (already wired up at `/admin/kaffy` with admin auth) — just add the Flag schema to `admin.ex`
- **Sentence context**: Capture optional `context_sentence_id` when flagging a word from a sentence context
- **Pending flag count**: Show on existing admin dashboard as a badge
- **Scope**: All surfaces at once (reusable component, marginal effort per surface)
- **UI**: Modal overlay for the flag form
- **Notification**: Dashboard badge only for v1 (no email)
- **Flag visibility**: Users don't see their own past flags for v1
- **Duplicates**: Users flag independently (no visibility into other users' flags)

---

## What Can Be Flagged

Two flaggable entity types:

| Entity | Where User Sees It | What's Wrong |
|--------|-------------------|--------------|
| **Word** | Dictionary, Word Detail, Flashcards | Bad translation, wrong inflection, missing form, wrong metadata |
| **Sentence** | Write Sentence exercises, Word Detail examples | Bad Serbian text, wrong English translation, wrong word annotation |

> **Design note**: We don't need to track _which specific inflected form_ is wrong at the DB level. The user can describe it in the free-text note. Keeping it to just word + sentence avoids overcomplicating the schema while still capturing all issues.

---

## Where the Flag Button Appears

| Surface | Flaggable | Placement |
|---------|-----------|-----------|
| **Word Detail page** | Word | Top toolbar, next to script toggle |
| **Dictionary search results** | Word | Small icon on each result card |
| **Flashcard** (flip/write) | Word | Top-right corner of current card |
| **Write Sentence exercise** | Sentence | Near the sentence text, toolbar area |
| **Example sentences** (in Word Detail) | Sentence | Small icon next to each sentence |

The button should be small and unobtrusive — a flag/report icon, not a full button with text.

---

## User Flow

1. User sees a word/sentence with an issue
2. Clicks the flag icon (small, always visible, only for logged-in users)
3. A modal overlay appears with:
   - **Category** dropdown (required): pick what's wrong
   - **Note** text field (optional): describe the issue
   - **Submit** button
4. On submit: flag saved, modal closes, brief flash message ("Thanks, reported!")
5. User continues what they were doing (no page redirect)

### Flag Categories

For **words**:
- Incorrect translation
- Wrong inflected form
- Missing form
- Other

For **sentences**:
- Wrong Serbian text
- Wrong English translation
- Other

---

## Data Model

### `flags` table

| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| user_id | bigint FK → users | Who reported |
| flaggable_type | string | `"word"` or `"sentence"` |
| flaggable_id | bigint | ID of the word or sentence |
| category | string | One of the predefined categories |
| note | text | Optional free-text from user |
| context_sentence_id | bigint FK → sentences | Optional — which sentence was showing when user flagged a word |
| status | string | `pending` → `resolved` / `dismissed` |
| resolved_by_id | bigint FK → users | Admin who handled it (nullable) |
| resolved_at | utc_datetime | When it was handled (nullable) |
| timestamps | | created_at, updated_at |

**Indexes**: (user_id), (flaggable_type, flaggable_id), (status)

**Constraint**: unique on (user_id, flaggable_type, flaggable_id) where status = 'pending' — one pending flag per user per entity.

---

## Context: `Ohmyword.Reports`

```elixir
Reports.create_flag(user, flaggable_type, flaggable_id, category, note, opts)
Reports.list_pending_flags()
Reports.resolve_flag(flag, admin_user, status)  # status: :resolved or :dismissed
Reports.count_pending_flags()
Reports.user_has_pending_flag?(user, flaggable_type, flaggable_id)
```

---

## Admin Review — Kaffy

Add the Flag schema to `lib/ohmyword_web/admin.ex`:

```elixir
reports: [
  resources: [
    flag: [schema: Ohmyword.Reports.Flag]
  ]
]
```

Kaffy gives us for free:
- List all flags with sorting/filtering
- View individual flag details
- Edit status (pending → resolved/dismissed)
- See related user info
- Already behind admin auth (`/admin/kaffy` with `:admins_only` pipeline)

Additionally, show a **pending flag count badge** on the existing admin dashboard LiveView to surface new flags without having to check Kaffy.

---

## Implementation Plan

### Step 1: Migration — create `flags` table
- New file: `priv/repo/migrations/TIMESTAMP_create_flags.exs`
- Columns as defined in Data Model above
- Indexes on (user_id), (flaggable_type, flaggable_id), (status)
- Unique partial index: (user_id, flaggable_type, flaggable_id) WHERE status = 'pending'

### Step 2: Schema — `Ohmyword.Reports.Flag`
- New file: `lib/ohmyword/reports/flag.ex`
- Ecto schema with belongs_to :user, belongs_to :resolved_by (User), belongs_to :context_sentence (Sentence)
- `changeset/2` for creation (validates required: user_id, flaggable_type, flaggable_id, category)
- `resolve_changeset/2` for admin resolution (status, resolved_by_id, resolved_at)
- Ecto.Enum values for category and status

### Step 3: Context — `Ohmyword.Reports`
- New file: `lib/ohmyword/reports.ex`
- `create_flag/2` — insert flag, handle unique constraint error gracefully ("already flagged")
- `list_pending_flags/0` — ordered by newest, preloads user
- `count_pending_flags/0` — for admin dashboard badge
- `resolve_flag/3` — update status + resolved_by_id + resolved_at
- `user_has_pending_flag?/3` — check before showing flag button state

### Step 4: Flag modal component
- File: `lib/ohmyword_web/components/core_components.ex`
- Add `flag_button/1` — small icon button, takes flaggable_type, flaggable_id, optional context_sentence_id
  - Only renders for logged-in users (check current_scope)
  - Sends JS command to show modal
- Add `flag_modal/1` — uses existing `modal` component
  - Category dropdown (options change based on flaggable_type)
  - Note textarea (optional)
  - Hidden inputs for flaggable_type, flaggable_id, context_sentence_id
  - Submit via phx-submit

### Step 5: Flag event handling — LiveComponent or shared helper
- **Option A (preferred)**: `FlagFormComponent` LiveComponent — self-contained, handles its own events, avoids duplication across 4 LiveViews
- **Option B**: Shared `OhmywordWeb.FlagHelpers` module that each LiveView delegates to
- Handler: validate → `Reports.create_flag/2` → put_flash → close modal

### Step 6: Add flag button to all surfaces
- `lib/ohmyword_web/live/word_detail_live.ex` — flag word (top toolbar, next to script toggle)
- `lib/ohmyword_web/live/dictionary_live.ex` — flag word (each result card)
- `lib/ohmyword_web/live/flashcard_live.ex` — flag word (card top-right corner)
- `lib/ohmyword_web/live/write_sentence_live.ex` — flag sentence (toolbar area)
- Word Detail example sentences — flag sentence (icon next to each sentence)

### Step 7: Kaffy integration
- File: `lib/ohmyword_web/admin.ex`
- Add reports resource group with Flag schema to `create_resources/1`

### Step 8: Admin dashboard badge
- File: `lib/ohmyword_web/live/admin_dashboard_live.ex`
- Call `Reports.count_pending_flags()` on mount
- Show count badge linking to Kaffy flags list

### Step 9: Tests
- New file: `test/ohmyword/reports_test.exs` — context tests (create, resolve, dedup constraint, count)
- New file: `test/support/fixtures/reports_fixtures.ex` — flag fixtures
- Add flag button interaction tests to existing LiveView test files

### Step 10: Authorization policy
- Check `lib/ohmyword/policy.ex` (LetMe) for any needed updates
- Members can create flags, admins can resolve/dismiss

---

## Files to Create/Modify

| File | Action |
|------|--------|
| `priv/repo/migrations/*_create_flags.exs` | Create |
| `lib/ohmyword/reports/flag.ex` | Create |
| `lib/ohmyword/reports.ex` | Create |
| `lib/ohmyword_web/components/core_components.ex` | Modify — add flag_button, flag_modal |
| `lib/ohmyword_web/live/word_detail_live.ex` | Modify — add flag button |
| `lib/ohmyword_web/live/dictionary_live.ex` | Modify — add flag button |
| `lib/ohmyword_web/live/flashcard_live.ex` | Modify — add flag button |
| `lib/ohmyword_web/live/write_sentence_live.ex` | Modify — add flag button |
| `lib/ohmyword_web/admin.ex` | Modify — add Flag to Kaffy |
| `lib/ohmyword_web/live/admin_dashboard_live.ex` | Modify — add pending count badge |
| `test/ohmyword/reports_test.exs` | Create |
| `test/support/fixtures/reports_fixtures.ex` | Create |

---

## Verification

1. `mix ecto.migrate` — flags table created
2. `mix test` — all existing + new tests pass
3. `mix precommit` — compile, format, test all green
4. Manual: log in → Word Detail → click flag → modal opens → select category → submit → flash "Thanks, reported!"
5. Manual: flag same word again → "already flagged" feedback
6. Manual: verify flag button on all surfaces (dictionary, flashcards, write sentence, example sentences)
7. Manual: check Kaffy at `/admin/kaffy` → flag appears in reports section
8. Manual: admin dashboard shows pending flag count badge
