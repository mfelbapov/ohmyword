# Codebase Refactoring Audit

> Conducted 2026-02-14. Covers all of `lib/ohmyword/` and `lib/ohmyword_web/`.

---

## Summary

The codebase is well-structured and follows Phoenix conventions. The main refactoring opportunities fall into three categories: **duplicated logic across linguistics inflectors**, **oversized LiveView modules**, and **minor structural improvements** in the web layer.

---

## 🔴 High-Impact

### 1. Duplicated Helper Functions Across Inflectors

**Problem:** Several private helper functions are copy-pasted between `nouns.ex` and `adjectives.ex` (and sometimes `verbs.ex`/`sound_changes.ex`):

| Function | Locations |
|---|---|
| `remove_fleeting_a/1` + `find_and_remove_fleeting_a/1` | `nouns.ex:324-361`, `adjectives.ex:160-194` |
| `is_consonant?/1` | `nouns.ex:364`, `adjectives.ex:195` |
| `is_vowel?/1` | `verbs.ex:261`, `sound_changes.ex:186` |

**Fix:** Extract these into `SoundChanges` (or a new `Ohmyword.Linguistics.Helpers` module) and call from all inflectors. `SoundChanges` already exists and is the natural home for phonological utilities.

**Impact:** Eliminates ~80 lines of duplication and ensures bug fixes propagate to all POS.

---

### 2. Repeated Irregular Forms Override Pattern

**Problem:** Every inflector independently implements the "check irregular_forms, apply overrides" pattern:

- `verbs.ex`: Reads `irregular_forms` from metadata, threads it through 6+ functions, checks `Map.get(irregular_forms, tag)` at each generation step
- `adjectives.ex:415-425`: Dedicated `apply_irregular_overrides/2` at the end
- `numerals.ex:451-461`: Nearly identical `apply_irregular_overrides/2`
- `nouns.ex:117-120`: Inline `get_in(metadata, ["irregular_forms", form_tag])`

**Fix:** Extract a shared `Ohmyword.Linguistics.Helpers.apply_overrides(forms, metadata)` function. Each inflector generates forms normally, then pipes through the shared override function as a final step.

**Impact:** Standardizes override behavior and removes ~40 lines of scattered duplication.

---

### 3. `WordDetailLive` is 643 Lines — Extract Inflection Table Components

**Problem:** `word_detail_live.ex` contains 5 different `render_inflection_table/1` clauses (noun, verb, adjective, pronoun/numeral, invariable) totaling ~375 lines of inline HEEx. These are pure rendering functions with no state management.

**Fix:** Extract into a new `OhmywordWeb.InflectionTableComponents` module with function components:
- `noun_table(assigns)` 
- `verb_table(assigns)` 
- `adjective_table(assigns)` 
- `generic_forms_table(assigns)` (for pronouns, numerals, invariables)

**Impact:** Reduces `word_detail_live.ex` to ~270 lines and makes inflection tables independently testable and reusable.

---

## 🟡 Medium-Impact

### 4. Duplicated `toggle_script` Handler Across 4 LiveViews

**Problem:** This exact handler is repeated in `flashcard_live.ex:302`, `dictionary_live.ex:150`, `word_detail_live.ex:220`, `write_sentence_live.ex:301`:

```elixir
def handle_event("toggle_script", _params, socket) do
  new_mode = if socket.assigns.script_mode == :latin, do: :cyrillic, else: :latin
  {:noreply, assign(socket, script_mode: new_mode)}
end
```

**Fix:** Use a shared `on_mount` hook or `attach_hook` in a module like `OhmywordWeb.ScriptToggleHook` that handles this event and provides the `:script_mode` assign. All 4 LiveViews would simply `on_mount: [{OhmywordWeb.ScriptToggleHook, :default}]`.

**Impact:** Removes 12 lines of duplicate code and ensures consistent behavior.

---

### 5. Voice Assimilation Brute-Force in `SoundChanges`

**Problem:** `assimilate_voice/1` in `sound_changes.ex:115-184` is 70 lines of hardcoded `String.replace` calls (6 voiced consonants × 10 voiceless consonants = 60+ replacements).

**Fix:** Implement using a data-driven approach:

```elixir
@voiced_to_voiceless %{"ž" => "š", "z" => "s", "b" => "p", "d" => "t", "g" => "k", "đ" => "ć"}
@voiceless ~w(p t k s š č ć f h c)

def assimilate_voice(term) do
  Enum.reduce(@voiced_to_voiceless, term, fn {voiced, voiceless}, acc ->
    Enum.reduce(@voiceless, acc, fn vl, acc2 ->
      String.replace(acc2, voiced <> vl, voiceless <> vl)
    end)
  end)
end
```

**Impact:** Reduces 70 lines to ~10 lines, makes it easier to add reverse assimilation, and eliminates risk of missing a combination.

---

### 6. `admins_only` Pipeline Duplicates `:browser`

**Problem:** In `router.ex:21-32`, the `:admins_only` pipeline repeats all 7 plugs from `:browser` and adds 2 more:

```elixir
pipeline :admins_only do
  plug :accepts, ["html"]
  plug :fetch_session
  # ... (same 7 plugs as :browser)
  plug :require_authenticated_user
  plug OhmywordWeb.Plugs.RequireAdmin
end
```

**Fix:** Use `pipe_through [:browser, :require_authenticated_user]` and add `RequireAdmin` inline at the scope level, or define `:admins_only` as just the additional plugs and compose: `pipe_through [:browser, :admins_only]`.

**Impact:** Eliminates 7 lines of duplication and prevents drift between the two pipelines.

---

### 7. Pronouns Module — 834 Lines of Hardcoded Paradigms

**Problem:** `pronouns.ex` is the largest linguistics module at 834 lines. The bulk is hardcoded paradigm maps for personal, reflexive, interrogative, and possessive pronouns (~700 lines of data).

**Fix:** Move paradigm data to JSON/YAML files under `priv/linguistics/paradigms/` and load at compile time with `@external_resource` + `Code.eval_file` or `Jason.decode!`. The module itself would shrink to ~130 lines of logic.

**Impact:** Separates data from logic, makes paradigms editable without touching Elixir code, enables data-driven testing.

---

## 🟢 Low-Impact / Nice-to-Have

### 8. `Exercises` Context Does Too Much

**Problem:** `exercises.ex` (290 lines) handles three distinct responsibilities:
1. Sentence CRUD & query (`get_sentence!`, `get_random_sentence`, etc.)
2. Blank selection & answer checking (`select_blanks`, `check_answer`, `check_all_answers`)
3. Flashcard answer checking (`check_flashcard_answer`)

**Fix:** Consider splitting flashcard logic into its own module (`Ohmyword.Exercises.Flashcards`) or at minimum grouping the public API with clear section comments.

---

### 9. `Search` Module — Misplaced Doc Comment

**Problem:** In `search.ex:58-68`, there's a doc comment for `count_search_terms/0` that interrupts the private function documentation comments:

```elixir
# 1. Convert Cyrillic to Latin
@doc """
Returns the total number of search terms.
"""
def count_search_terms do ...
# 2. Strip diacritics (č→c, š→s, etc.)
# 3. Lowercase
defp normalize_query(query) do ...
```

The numbered comments (`# 1`, `# 2`, `# 3`) were clearly meant to describe `normalize_query/1` but got split by an insertion.

**Fix:** Move `count_search_terms/0` above the private functions section, and consolidate the normalization comments.

---

### 10. Missing `@script_toggle` Component in `WordComponents`

**Problem:** The `script_toggle` component lives in `core_components.ex:572` but is semantically a word/linguistics concern. It's imported via `OhmywordWeb.WordComponents` in all LiveViews but actually comes from `CoreComponents`.

**Fix:** Move the `script_toggle` component to `WordComponents` where it conceptually belongs, alongside `pos_badge`, `gender_badge`, etc.

---

### 11. `Vocabulary` and `Exercises` Contexts Duplicate `apply_filters/2`

**Problem:** Both `vocabulary.ex:208-222` and `exercises.ex:273-285` have their own `apply_filters/2` that use `Enum.reduce` over keyword opts. While the filter logic is different (different schemas), the pattern is identical.

**Fix:** This is a minor code smell — no action strictly needed, but documenting for awareness. If more contexts add filtering, consider a shared filter behavior or macro.

---

## Recommended Priority Order

1. **Extract shared helpers** (#1, #2) — Highest risk of divergent bugs
2. **Extract inflection table components** (#3) — Biggest single win for readability
3. **Script toggle hook** (#4) — Quick win, straightforward
4. **Data-driven voice assimilation** (#5) — Cleaner, more maintainable
5. **Fix admin pipeline** (#6) — Quick, prevents drift
6. Everything else as opportunity arises
