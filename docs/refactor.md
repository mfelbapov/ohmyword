# Codebase Refactoring Analysis

A comprehensive audit of the Ohmyword codebase identifying duplication, complexity hotspots, and structural improvements — organized by priority.

---

## 1. Linguistics Engine Duplication (High Priority)

The inflection engine modules have significant code duplication that increases maintenance burden and divergence risk.

### `is_vowel?/1` and `is_consonant?/1` — duplicated across 4 modules

| Function | File | Line | Visibility |
|----------|------|------|------------|
| `is_vowel?/1` | `linguistics/verbs.ex` | 261 | `defp` |
| `is_vowel?/1` | `linguistics/sound_changes.ex` | 186 | `def` |
| `is_consonant?/1` | `linguistics/nouns.ex` | 364 | `defp` |
| `is_consonant?/1` | `linguistics/adjectives.ex` | 195 | `defp` |

All implementations are identical. These should be extracted to a shared `Linguistics.Helpers` module with public functions, replacing all four private copies.

### `remove_fleeting_a/1` + `find_and_remove_fleeting_a/1` — duplicated identically

| File | Lines |
|------|-------|
| `linguistics/nouns.ex` | 324–362 |
| `linguistics/adjectives.ex` | 160–197 |

Both implementations use the same algorithm: check length < 3, find rightmost 'a' surrounded by consonants via `Enum.with_index |> Enum.reverse |> Enum.find`, remove it, rejoin. Extract to `Linguistics.Helpers`.

### Soft consonant constants — triplicated

| Constant | Adjectives (L27–29) | Numerals (L21–22) | Pronouns (L825–826) |
|----------|---------------------|--------------------|-----------------------|
| `@soft_consonants` | `~w(č ć š ž đ j)` | `~w(č ć š ž đ j)` | inline local var |
| `@soft_digraphs` | `~w(lj nj dž)` | `~w(lj nj dž)` | inline local var |
| `soft_stem?/1` | L151 | L376 | L824 |

All three `soft_stem?/1` functions are functionally identical. Extract constants and function to `Linguistics.Helpers`.

### `apply_irregular_overrides/2` — duplicated

| File | Line |
|------|------|
| `linguistics/adjectives.ex` | 416 |
| `linguistics/numerals.ex` | 452 |

Identical implementation: maps over `{form, tag}` tuples, replaces with `metadata["irregular_forms"]` overrides. Extract to `Linguistics.Helpers`.

### `iotate_with_clusters/1` — misplaced

- **Current location:** `linguistics/verbs.ex:397`
- **Better location:** `linguistics/sound_changes.ex` (189 lines, handles all other sound changes)

This function handles cluster-specific iotation (st→št, zd→žd, sl→šlj, sn→šnj) and falls back to `SoundChanges.iotate/1`. It belongs with the other sound change logic.

### `Pronouns.ex` — 833 lines of mostly hardcoded paradigm tables

The file is almost entirely static paradigm data. Consider moving the paradigm tables to a data file (JSON or module attribute map) loaded at compile time, leaving only the dispatch logic in the module.

### Suggested new module

```
lib/ohmyword/linguistics/helpers.ex
├── is_vowel?/1
├── is_consonant?/1
├── remove_fleeting_a/1
├── find_and_remove_fleeting_a/1
├── soft_consonants/0
├── soft_digraphs/0
├── soft_stem?/1
└── apply_irregular_overrides/2
```

---

## 2. Components Organization (High Priority)

### `core_components.ex` — 761 lines, mixed concerns

Six domain-specific exercise components are embedded in the generic UI component module:

| Component | Lines | Purpose |
|-----------|-------|---------|
| `script_toggle` | 572–586 | Latin/Cyrillic toggle |
| `direction_toggle` | 597–611 | SR→EN / EN→SR toggle |
| `practice_mode_toggle` | 622–637 | Flip/Write mode toggle |
| `pos_filter` | 649–665 | Part of speech dropdown |
| `category_filter` | 673–693 | Category dropdown |
| `difficulty_selector` | 704–732 | Difficulty level buttons |

**Recommendation:** Extract these to a dedicated `ExerciseComponents` module. The generic components (button, input, header, table, list, icon, modal, flash) stay in `core_components.ex`.

### `build_button_classes` (L149–174) and `build_input_classes` (L354–377)

Both share near-identical variant/size logic:
- Both apply `#{type}-#{variant}` naming
- Both skip size class when size is `"md"` (default)
- Both filter/flatten class arrays

Could consolidate into a shared `build_classes/3` helper.

### Error translation utilities (L737–760)

`translate_error/1` and `translate_errors/2` are Gettext-specific form helpers unrelated to UI components. Could move to a `FormHelpers` module.

### `word_components.ex` — 192 lines

- **`expand_abbreviation/1` (L110–126):** 17 function clauses that are a simple string mapping. Should be a map lookup:
  ```elixir
  @abbreviations %{"nom" => "Nominative", "gen" => "Genitive", ...}
  def expand_abbreviation(abbr), do: Map.get(@abbreviations, abbr, String.capitalize(abbr))
  ```

- **Color collision:** `gender_badge` (L25–29) and `case_color_classes` (L82–108) share overlapping color assignments — blue is used for both masculine gender and dative case, pink for both feminine gender and vocative case. This can cause visual confusion when badges appear alongside case-colored rows.

---

## 3. LiveView Complexity (Medium Priority)

### `WordDetailLive` — 642 lines

**Inflection table rendering: ~370 lines (57% of the file)**

| Table renderer | POS | Lines | Size |
|----------------|-----|-------|------|
| Noun table | noun | 227–265 | 39 lines |
| Verb table | verb | 267–416 | 150 lines |
| Adjective table | adjective | 418–531 | 114 lines |
| Pronoun/Numeral table | pronoun, numeral | 533–569 | 37 lines |
| Invariables fallback | other | 572–601 | 30 lines |

**Recommendation:** Extract to an `InflectionTableComponent` module. The 5 grammar constants at the top of the file (L15–26) could move to a shared `Linguistics.Constants` module:

| Constant | Line | Value |
|----------|------|-------|
| `@noun_cases` | 15 | `~w(nom gen dat acc voc ins loc)` |
| `@verb_persons` | 16 | `~w(1sg 2sg 3sg 1pl 2pl 3pl)` |
| `@person_labels` | 17–24 | pronoun label map |
| `@adj_genders` | 25 | `~w(m f n)` |
| `@adj_gender_labels` | 26 | gender abbreviation map |

### `FlashcardLive` — 462 lines

1. **Example sentence rendering duplicated** between flip mode (L111–120) and write mode (L213–222). The two blocks are identical except for margin class (`mt-6` vs `mt-4`). Extract to a shared component.

2. **Linguistic badge rendering triplicated** at L51–62 (flip front), L95–106 (flip back), and L131–142 (write mode prompt). Same markup three times — extract to `<.linguistic_badges>` component.

3. **Filter option building has two near-identical functions:**
   - `update_available_options` (L410–419): builds filter lists for POS/category availability
   - `build_filter_opts` (L426–440): builds filter list for word query

   Both extract `pos_filter` and `category_filter` from assigns and build conditional keyword lists. Could be unified.

4. **Filter event handlers** `filter_pos` (L347–367) and `filter_category` (L369–383) are nearly identical, differing only in the assign key.

### `WriteSentenceLive` — 425 lines

History state uses raw maps instead of structs:

- **Capture** (L251–262): pushes a 5-key map `%{sentence:, difficulty:, blanked_words:, blanked_positions:, tokens:}` onto a list
- **Restore** (L281–294): pattern-matches `[prev | rest]` and destructures the map

A `HistoryEntry` struct would add compile-time key validation and self-document the expected shape.

---

## 4. Performance Concern (Medium Priority)

### `AppInfo` plug — 3 database queries on every HTTP request

**File:** `lib/ohmyword_web/plugs/app_info.ex` (L27–33)

```elixir
def call(conn, _opts) do
  conn
  |> assign(:app_version, @app_version)
  |> assign(:word_count, Vocabulary.count_words())
  |> assign(:search_term_count, Search.count_search_terms())
  |> assign(:sentence_count, Exercises.count_sentences())
end
```

This runs in both `:browser` and `:admins_only` pipelines — every page load triggers 3 `SELECT COUNT(*)` queries. These counts change rarely (only on seed import or admin actions).

**Options:**
- **ETS cache with TTL:** Cache counts in ETS, refresh every N minutes
- **Application-level GenServer:** Periodic polling with `Process.send_after`
- **PubSub invalidation:** Broadcast cache-clear on vocabulary/sentence changes

---

## 5. Router & Auth (Medium Priority)

### Pipeline duplication

**`:browser` pipeline** (L6–15) — 8 plugs:
1. `:accepts, ["html"]`
2. `:fetch_session`
3. `:fetch_live_flash`
4. `:put_root_layout`
5. `:protect_from_forgery`
6. `:put_secure_browser_headers`
7. `:fetch_current_scope_for_user`
8. `Plugs.AppInfo`

**`:admins_only` pipeline** (L21–32) — 10 plugs:
1–7. Same as `:browser`
8. `:require_authenticated_user`
9. `Plugs.RequireAdmin`
10. `Plugs.AppInfo`

70% overlap (7 of 10 unique plugs). Could define a shared `:base_browser` pipeline with the common 7 plugs, then compose:

```elixir
pipeline :browser do
  plug :base_browser
  plug Plugs.AppInfo
end

pipeline :admins_only do
  plug :base_browser
  plug :require_authenticated_user
  plug Plugs.RequireAdmin
  plug Plugs.AppInfo
end
```

### `UserAuth` — 327 lines, 5 distinct responsibilities

| Section | Lines | Responsibility |
|---------|-------|---------------|
| Constants | 10–27 | Cookie config, session reissue config |
| Login/Logout | 29–60 | Session creation and destruction |
| Session/Token management | 62–181 | Token retrieval, reissue, cookie handling |
| LiveView `on_mount` callbacks | 183–274 | 4 mount hooks |
| Plug helpers | 276–325 | HTTP auth guards, redirects |

The `require_authenticated_user` logic is implemented twice:
- **As plug** (L287–297): checks `conn.assigns.current_scope.user`
- **As `on_mount` callback** (L219–232): checks `socket.assigns.current_scope.user`

Both do the same conceptual check with different conn/socket APIs. This is inherent to Phoenix's dual HTTP/LiveView architecture, but could be made more explicit with a shared `authenticated?/1` predicate.

---

## 6. Test Infrastructure (Low Priority)

### Large test files

| Test file | Lines |
|-----------|-------|
| `test/ohmyword/linguistics/verbs_test.exs` | 1,616 |
| `test/ohmyword/linguistics/nouns_test.exs` | 1,503 |
| `test/ohmyword_web/live/flashcard_live_test.exs` | 500 |

### Repeated `%Word{}` struct creation

Every `describe` block in linguistics tests has a setup block creating an in-memory `%Word{}`:

```elixir
# verbs_test.exs — this pattern repeats ~15 times
setup do
  word = %Word{
    term: "čitati",
    part_of_speech: :verb,
    verb_aspect: :imperfective,
    conjugation_class: "a-verb"
  }
  {:ok, word: word, forms: Verbs.generate_forms(word)}
end
```

```elixir
# nouns_test.exs — this pattern repeats ~20 times
setup do
  word = %Word{
    term: "grad",
    part_of_speech: :noun,
    gender: :masculine,
    animate: false,
    declension_class: "consonant"
  }
  {:ok, word: word, forms: Nouns.generate_forms(word)}
end
```

**Note:** `VocabularyFixtures` exists with `word_fixture/1`, `noun_fixture/1`, `verb_fixture/1`, etc. — but linguistics tests don't use them because they need in-memory structs (not persisted). A parallel set of in-memory word builders could reduce boilerplate.

### No shared assertion helpers

Tests rely on raw ExUnit assertions. Common patterns like checking that a specific form tag has a specific value:

```elixir
assert {"gradovi", "nom_pl"} in forms
```

Could benefit from a helper like `assert_form(forms, "nom_pl", "gradovi")` that provides better error messages.

### `FlashcardLiveTest` — 500 lines mixing concerns

Tests cover 12 distinct areas in a single file:
1. Basic rendering & empty states
2. Word display & badges
3. Flip mode basics
4. Script toggling
5. Navigation (next/previous)
6. Example sentences
7. POS filter
8. Category filter
9. Practice mode toggle
10. Write mode answer checking
11. Filter interaction with write mode
12. Cross-filter interaction

Could split into `FlashcardFlipModeTest`, `FlashcardWriteModeTest`, and `FlashcardFilterTest`.

---

## 7. Answer Checking Logic (Low Priority)

### Three related functions in `Exercises` context

| Function | Lines | Scope |
|----------|-------|-------|
| `check_answer/2` | 166–184 | Single sentence blank |
| `check_all_answers/2` | 192–207 | All blanks in a sentence (calls `check_answer/2`) |
| `check_flashcard_answer/3` | 240–253 | Flashcard translation |

**Shared logic:** All use the private `normalize/1` function (L265–271) for input normalization (trim → to_latin → strip_diacritics → downcase). Return types are consistent: `{:correct, matched_form}` or `{:incorrect, expected_forms}`.

**Differences:**
- `check_answer/2` retrieves expected forms from `SearchTerm` table
- `check_flashcard_answer/3` builds expected forms from word translations, and additionally strips internal spaces
- `check_all_answers/2` is a batch wrapper around `check_answer/2`

The current organization is reasonable — `check_all_answers/2` already reuses `check_answer/2`. If the module grows further, extracting to an `AnswerChecking` module would make sense, but at current size (~90 lines for all three + helpers) it's not urgent.

---

## Summary — Effort vs Impact

| Area | Priority | Effort | Impact |
|------|----------|--------|--------|
| Linguistics engine duplication | High | Low | Eliminates 5 duplicated functions across 8 files |
| Components extraction | High | Low | Cleaner separation of generic vs domain components |
| LiveView table extraction | Medium | Medium | Removes 370 lines from WordDetailLive |
| AppInfo caching | Medium | Low | Eliminates 3 unnecessary DB queries per request |
| Router pipeline consolidation | Medium | Low | Removes 7 duplicated plug declarations |
| FlashcardLive dedup | Medium | Low | Removes triplicated badge/sentence markup |
| Test infrastructure | Low | Medium | Better test organization and error messages |
| Answer checking extraction | Low | Low | Marginal improvement at current size |
