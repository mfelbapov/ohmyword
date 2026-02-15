# English Word Search in Dictionary

## Context

The dictionary currently only supports Serbian search (Latin, Cyrillic, fuzzy diacritics). Users want to search by English translation to find the Serbian word. English translations are already stored in `vocabulary_words.translation` (primary) and `.translations` (alternatives). Since English has no inflection, this is a straightforward direct query — no need for the `search_terms` cache table.

## Approach

- **Auto-detect**: Try Serbian search first (unchanged), fall back to English if no Serbian results
- **Word-level matching**: "throw" matches "to throw" (any word in the translation matches)
- **Direct query**: Query `vocabulary_words` table directly via `string_to_array` — no new tables or migrations

## Changes

### 1. `lib/ohmyword/search/search.ex`

- Add `alias Ohmyword.Vocabulary.Word`
- Rename current `lookup/1` body → `lookup_serbian/1` (private)
- New `lookup/1`: calls `lookup_serbian`, if empty falls back to `lookup_english`
- New `lookup_english/1` (private): queries `vocabulary_words` where any word in `translation` or `translations` matches the query exactly (word-level, case-insensitive via `string_to_array(lower(...), ' ')`)
- New `find_matching_translation/2` (private): returns the specific translation string that contained the match
- English results use `form_tag: "translation"` and `matched_form` = the matching English translation string

### 2. `lib/ohmyword_web/live/dictionary_live.ex`

- Update placeholder: `"Search Serbian or English words..."`
- Update hint text: `"Enter a Serbian or English word to look up its meaning"` / `"Works with Latin or Cyrillic script, inflected forms, and English translations"`
- **Skip Cyrillic conversion for English results**: On line 98, check `result.form_tag == "translation"` — if so, render `result.matched_form` directly instead of through `display_term/2` (avoids garbled Cyrillic for English text)

### 3. `test/ohmyword/search/search_test.exs` (new file)

Tests for:
- English search finds word by primary translation word match
- English search finds word by alternative translation word match
- English search is case-insensitive
- Serbian results take priority over English (auto-detect)
- No results returns empty list
- Word-level matching: "throw" matches "to throw" but not "throwback"

## Files touched
- `lib/ohmyword/search/search.ex` — modify
- `lib/ohmyword_web/live/dictionary_live.ex` — modify
- `test/ohmyword/search/search_test.exs` — create

## Verification
1. `mix precommit` passes (compile + format + tests)
2. Manual: start server, go to dictionary, search "dog" → should show "pas"
3. Manual: search "throw" → should show "baciti" with matched form "to throw"
4. Manual: search "pas" → still works as Serbian search (unchanged)
5. Manual: toggle Cyrillic script → Serbian results convert, English matched_form stays in Latin
