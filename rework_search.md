# Rework: Preserve Diacritics for Correct Cyrillic Display

## Problem

All data is stored in ASCII-only Latin (diacritics stripped). When toggling to Cyrillic:
- `to_cyrillic("reci")` → "реци" (wrong! ц = ts, should be ћ = ć for "reći")
- `to_cyrillic("rec")` → "рец" (wrong! should be "реч" for "reč")
- `to_cyrillic("Rec je mocna.")` → "Рец је моцна." (wrong! should be "Реч је моћна.")

Root cause: `č`, `ć`, `c` all collapse to `c` when stripped. Same for `š`/`s`, `ž`/`z`, `đ`/`dj`. Cyrillic conversion can't reconstruct the original.

## Solution

**Store diacritical forms for display, keep ASCII for search matching.**

Serbian Latin script uses diacritics (č, ć, š, ž, đ) — displaying them is correct behavior even in Latin mode. The ASCII stripping should only happen for search matching (where users may type without diacritics).

## Changes

### Phase 1: Schema — Add `display_form` to `search_terms`

**File: `priv/repo/migrations/20260126194126_create_vocabulary_schema.exs`**

Add `display_form` column to the `search_terms` table (not null, string). This stores the diacritical form for display. The existing `term` column stays as ASCII for search matching.

```
add :display_form, :string, null: false
```

**File: `lib/ohmyword/search/search_term.ex`**

- Add `field :display_form, :string` to schema
- Add `display_form` to `@required_fields`
- Apply `lowercase_display_form` in changeset (same pattern as `lowercase_term`)

### Phase 2: Dispatcher — Stop stripping diacritics

**File: `lib/ohmyword/linguistics/dispatcher.ex`**

Remove the `Transliteration.strip_diacritics/1` call. The Dispatcher should return raw diacritical forms as the engine produces them. Consumers that need ASCII will strip themselves.

Before:
```elixir
inflector.generate_forms(word)
|> Enum.map(fn {form, tag} ->
  {Transliteration.strip_diacritics(form), tag}
end)
```

After:
```elixir
inflector.generate_forms(word)
```

Remove the `alias Ohmyword.Linguistics.Transliteration` import since it's no longer used.

### Phase 3: CacheManager — Store both forms

**File: `lib/ohmyword/linguistics/cache_manager.ex`**

The `insert_forms/2` function receives diacritical forms from the Dispatcher. It needs to:
1. Strip diacritics for `term` (ASCII, for matching)
2. Keep original for `display_form` (diacritical, for display)

Add `alias Ohmyword.Utils.Transliteration` (or `Ohmyword.Linguistics.Transliteration`).

```elixir
defp insert_forms(word_id, forms) do
  now = DateTime.utc_now() |> DateTime.truncate(:second)

  entries =
    Enum.map(forms, fn {form, form_tag} ->
      %{
        term: form |> Transliteration.strip_diacritics() |> String.downcase(),
        display_form: String.downcase(form),
        form_tag: String.downcase(form_tag),
        word_id: word_id,
        source: :engine,
        locked: false,
        inserted_at: now,
        updated_at: now
      }
    end)

  # ... rest unchanged
end
```

### Phase 4: Search — Return `display_form` for display

**File: `lib/ohmyword/search/search.ex`**

Change `lookup/1` to return `display_form` as `matched_form`:

```elixir
|> Enum.map(fn search_term ->
  %{
    word: search_term.word,
    matched_form: search_term.display_form,   # was: search_term.term
    form_tag: search_term.form_tag
  }
end)
```

The deduplication logic comparing `matched_form == word.term` still works because both are now diacritical.

### Phase 5: Seed Loader — Strip for `term`, keep for `display_form`

**File: `priv/repo/seeds.exs`**

Update `insert_search_term/2` to handle the new schema:

```elixir
defp insert_search_term(word, %{"term" => term, "form_tag" => form_tag}) do
  %SearchTerm{}
  |> SearchTerm.changeset(%{
    term: term |> Transliteration.strip_diacritics() |> String.downcase(),
    display_form: String.downcase(term),
    form_tag: String.downcase(form_tag),
    word_id: word.id,
    source: :seed,
    locked: true
  })
  |> Repo.insert()
end
```

Add `alias Ohmyword.Utils.Transliteration` (or the Linguistics one) at the top of the module.

### Phase 6: Seed Data — Add diacritics

**File: `priv/repo/vocabulary_seed.json`**

This is the biggest change. All 284 entries need proper Serbian Latin diacritics in:

1. **`term`** (top-level) — already done for ~25 words (reč, trčati, peći, etc.), but ~260 words still need review
2. **`example_sentence_rs`** — all currently ASCII, need diacritics (e.g., "Rec je mocna." → "Reč je moćna.")
3. **`forms[].term`** — all currently ASCII, need diacritics (e.g., "reci" → "reči" for noun, "reći" for verb)
4. **`grammar_metadata`** values — stems, irregular_forms (some already have diacritics, review all)

**Approach**: Process in batches by part of speech. Use Serbian language knowledge to add correct diacritics. The key ambiguities to get right:
- `c` → `c`, `č`, or `ć` depending on the word
- `s` → `s` or `š`
- `z` → `z` or `ž`
- `dj` → `dj` or `đ` (note: "dj" in ASCII always means "đ" in our data)

### Phase 7: Validation Test — Now compares diacritical forms

**File: `test/ohmyword/linguistics/inflector_validation_test.exs`**

No code changes needed. The test compares engine output (from Dispatcher) against seed forms. Both will now be diacritical:
- Engine: Dispatcher no longer strips → diacritical output
- Seed: forms array now has diacritics

The `normalize_forms/1` function lowercases but doesn't strip, so comparisons will be diacritics-aware. This is correct.

### Phase 8: Dispatcher Test — Update expected values

**File: `test/ohmyword/linguistics/dispatcher_test.exs`**

Update assertions to expect diacritical forms:

```elixir
# Before:
assert {"pisem", "pres_1sg"} in forms
assert [{"kuca", "base"}] = forms

# After:
assert {"pišem", "pres_1sg"} in forms
assert [{"kuća", "base"}] = forms
```

Lines to update:
- L19: `{"pas", "nom_sg"}` → stays (no diacritics in "pas")
- L20: `{"pasa", "gen_sg"}` → stays (no diacritics needed — well, it depends on the actual form. "pas" gen is "psa" which has no diacritics)
- L29: `{"pisati", "inf"}` → stays (no diacritics in "pisati")
- L30: `{"pisem", "pres_1sg"}` → `{"pišem", "pres_1sg"}`
- L44: `{"kuca", "base"}` → `{"kuća", "base"}`

### Phase 9: Delete Linguistics.Transliteration module

**File: `lib/ohmyword/linguistics/transliteration.ex`**

This module existed solely to strip diacritics from engine output at the Dispatcher level. With the Dispatcher no longer stripping, this module has no callers. Delete it.

The `Utils.Transliteration.strip_diacritics/1` function already exists and is used by Search and CacheManager for normalizing queries and search keys. All stripping should go through that one module.

## Data Flow After Changes

```
INFLECTION ENGINE (Nouns, Verbs, etc.)
  │  produces diacritical forms: "pišeš", "reči", "kuća"
  ▼
DISPATCHER (no longer strips)
  │  passes through: [{"pišeš", "pres_2sg"}, ...]
  ▼
CACHE MANAGER
  │  stores BOTH:
  │    term = "pises"      (ASCII, for search matching)
  │    display_form = "pišeš"  (diacritical, for display)
  ▼
SEARCH_TERMS TABLE
  │  term: "pises"  |  display_form: "pišeš"  |  form_tag: "pres_2sg"
  ▼
SEARCH.LOOKUP("pises") or SEARCH.LOOKUP("pišeš") or SEARCH.LOOKUP("пишеш")
  │  all normalize to "pises" for matching
  │  returns matched_form: "pišeš" (from display_form)
  ▼
DISPLAY (flashcard or dictionary)
  │  Latin mode:   "pišeš"  (proper Serbian Latin)
  │  Cyrillic mode: to_cyrillic("pišeš") → "пишеш" ✓ CORRECT
```

## Execution Order

1. Phase 1: Schema changes (migration + SearchTerm schema)
2. Phase 9: Delete `Linguistics.Transliteration` module
3. Phase 2: Dispatcher changes (remove stripping)
4. Phase 3: CacheManager changes (store both forms)
5. Phase 4: Search changes (return display_form)
6. Phase 5: Seed loader changes
7. Phase 8: Dispatcher test updates
8. Phase 6: Seed data diacritics (biggest effort — batch by POS)
9. Phase 7: Run validation tests to verify
10. Run `mix test` to ensure nothing breaks
11. `mix ecto.reset` to re-seed with diacritical data

## Risk & Notes

- **No production data to migrate** — app not in production, `mix ecto.reset` is sufficient
- **Seed data is the hardest part** — 284 words × (term + forms + example sentences + metadata). Needs Serbian language expertise for correct diacritics placement
- **Engine already produces diacritics** — the inflector modules (Nouns, Verbs, etc.) already work with diacritical forms internally. We're just unblocking that output.
- **Latin display improves too** — users will see proper Serbian Latin (with diacritics) even without toggling to Cyrillic
