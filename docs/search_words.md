# Search Words Feature - Implementation Plan

## Recommendation: Dedicated Dictionary Page

**Route:** `/dictionary`
**Navbar:** Add "Dictionary" link

### Rationale

- Flashcards = practice/learning (random words, card flip)
- Dictionary = lookup/reference (specific word search)
- Different use cases deserve separate pages
- Navbar link makes it discoverable

---

## Implementation

### 1. Add Route

**File:** `lib/ohmyword_web/router.ex`

Add to the `:public` live_session (around line 38):

```elixir
live "/dictionary", DictionaryLive, :index
```

### 2. Add Navbar Link

**File:** `lib/ohmyword_web/components/layouts/root.html.heex`

After the Flashcards link, add:

```heex
<li>
  <.link href={~p"/dictionary"} class="flex items-center gap-1">
    <.icon name="hero-magnifying-glass" class="size-4" />
    <span class="hidden sm:inline">Dictionary</span>
  </.link>
</li>
```

### 3. Create DictionaryLive

**File:** `lib/ohmyword_web/live/dictionary_live.ex`

Key features:
- Live search with 300ms debounce (responsive, backend is fast)
- Call existing `Ohmyword.Search.lookup/1`
- Display results as cards with badges (reuse pattern from FlashcardLive)
- Script toggle (Latin/Cyrillic) like Flashcards
- Show matched inflected form when different from base word
- Empty states for no query and no results

### 4. Extract Shared Components (Optional)

Move badge components from `flashcard_live.ex` to a shared module:
- `pos_badge` (part of speech)
- `gender_badge`
- `aspect_badge`
- `animate_badge`

---

## Search UX

| Feature | Design |
|---------|--------|
| Input | Full-width search box, autofocus |
| Trigger | Live search on `phx-change` with 300ms debounce |
| Results | Cards showing: term, translation, badges, matched form, example sentence |
| Empty (no query) | Helpful hint about Latin/Cyrillic support |
| Empty (no results) | "No words found" message |
| Mobile | Icon-only navbar link, full-width cards |

---

## Files to Modify/Create

| Action | File |
|--------|------|
| Modify | `lib/ohmyword_web/router.ex` |
| Modify | `lib/ohmyword_web/components/layouts/root.html.heex` |
| Create | `lib/ohmyword_web/live/dictionary_live.ex` |
| Optional | `lib/ohmyword_web/components/word_components.ex` |

---

## Verification

1. Run `mix phx.server`
2. Navigate to `/dictionary`
3. Test search with Latin input (e.g., "kuća")
4. Test search with Cyrillic input (e.g., "кућа")
5. Test inflected form search (should show base word + matched form)
6. Verify navbar link appears on desktop and mobile
7. Run `mix test` to ensure no regressions
