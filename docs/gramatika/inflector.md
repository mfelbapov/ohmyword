# Phase 1: Inflector Behaviour & Dispatcher Foundation

## Objective

Create the foundational architecture for the Serbian word inflection rule engine. This enables parallel development of part-of-speech-specific inflectors.

---

## Files to Create

```
lib/ohmyword/linguistics/
├── inflector.ex          # Behaviour definition
├── dispatcher.ex         # Routes words to correct inflector
└── cache_manager.ex      # Regenerates search_terms from rules
```

---

## 1. Inflector Behaviour (`inflector.ex`)

Define a behaviour that all POS-specific inflectors must implement.

### Callbacks

```elixir
@callback applicable?(word :: Ohmyword.Vocabulary.Word.t()) :: boolean()
```
Returns `true` if this inflector handles the given word's part of speech.

```elixir
@callback generate_forms(word :: Ohmyword.Vocabulary.Word.t()) :: [
  {term :: String.t(), form_tag :: String.t()}
]
```
Returns a list of `{inflected_form, grammatical_tag}` tuples. The `term` should be lowercase Latin script.

### Example Return Value

For the noun "pas" (dog):
```elixir
[
  {"pas", "nom_sg"},
  {"psa", "gen_sg"},
  {"psu", "dat_sg"},
  {"psa", "acc_sg"},
  {"pse", "voc_sg"},
  {"psom", "ins_sg"},
  {"psu", "loc_sg"},
  {"psi", "nom_pl"},
  ...
]
```

---

## 2. Dispatcher (`dispatcher.ex`)

Routes a word to the correct inflector module.

### Public API

```elixir
Ohmyword.Linguistics.Dispatcher.inflect(word)
# => [{term, form_tag}, ...]

Ohmyword.Linguistics.Dispatcher.get_inflector(word)
# => Ohmyword.Linguistics.Nouns | ... | nil
```

### Implementation

- Maintain a list of inflector modules (order matters for fallback)
- Iterate through list, return first where `applicable?(word)` returns true
- Call `generate_forms/1` on the matched inflector
- If no inflector matches, return empty list or raise

### Inflector Registry

For now, create placeholder module atoms (they don't exist yet):

```elixir
@inflectors [
  Ohmyword.Linguistics.Nouns,
  Ohmyword.Linguistics.Verbs,
  Ohmyword.Linguistics.Adjectives,
  Ohmyword.Linguistics.Pronouns,
  Ohmyword.Linguistics.Numerals,
  Ohmyword.Linguistics.Invariables  # adverbs, prepositions, conjunctions, particles, interjections
]
```

The dispatcher should handle missing modules gracefully (check if module is loaded via `Code.ensure_loaded?/1`).

---

## 3. Cache Manager (`cache_manager.ex`)

Handles regenerating `search_terms` from the rule engine.

### Public API

```elixir
Ohmyword.Linguistics.CacheManager.regenerate_all()
# Regenerates search_terms for ALL vocabulary_words

Ohmyword.Linguistics.CacheManager.regenerate_word(word_id)
# Regenerates search_terms for a single word

Ohmyword.Linguistics.CacheManager.regenerate_word(word)
# Accepts a Word struct directly
```

### Regeneration Logic

For `regenerate_word/1`:

1. Load the word (if given ID) with any needed preloads
2. Call `Dispatcher.inflect(word)` to get forms
3. Delete existing `search_terms` for this word WHERE `locked = false`
4. Insert new `search_terms` with:
   - `term`: the inflected form (lowercase)
   - `form_tag`: the grammatical tag
   - `word_id`: the word's ID
   - `source`: `:engine`
   - `locked`: `false`
5. Return `{:ok, count}` with number of forms created

For `regenerate_all/0`:

1. Stream all `vocabulary_words`
2. For each word, call `regenerate_word/1`
3. Use transaction or batch for performance
4. Return summary `{:ok, %{words: n, forms: m}}`

### Preserve Manual Corrections

Critical: The `locked = true` rows must NOT be deleted. The regeneration only touches `locked = false` rows.

---

## 4. Stub Inflector for Testing (`stub_inflector.ex`)

Create one working stub to prove the architecture works:

```
lib/ohmyword/linguistics/stub_inflector.ex
```

### Implementation

- `applicable?/1`: Returns true for ANY word (temporary catch-all)
- `generate_forms/1`: Returns just the root form with tag `"base"`

```elixir
def generate_forms(word) do
  [{String.downcase(word.term), "base"}]
end
```

This lets you test the full pipeline before real inflectors exist.

---

## 5. Tests

Create test files:

```
test/ohmyword/linguistics/dispatcher_test.exs
test/ohmyword/linguistics/cache_manager_test.exs
```

### Dispatcher Tests

- Returns empty list when no inflector matches (with stub removed)
- Returns forms when stub inflector is active
- Handles nil/missing word gracefully

### Cache Manager Tests

- `regenerate_word/1` creates search_terms with `source: :engine`
- `regenerate_word/1` preserves `locked: true` entries
- `regenerate_word/1` deletes old `locked: false` entries before inserting
- `regenerate_all/0` processes multiple words

### Test Fixtures

Use existing seed data or create test fixtures for:
- A noun (pas)
- A verb (pisati)
- An invariable (i)

---

## 6. Integration Point

After this phase, the parallel agents will create:

| Module | Replaces stub for |
|--------|-------------------|
| `Nouns` | `part_of_speech == :noun` |
| `Verbs` | `part_of_speech == :verb` |
| `Adjectives` | `part_of_speech == :adjective` |
| `Pronouns` | `part_of_speech == :pronoun` |
| `Numerals` | `part_of_speech == :numeral` |
| `Invariables` | adverb, preposition, conjunction, particle, interjection |

Each agent's module just needs to implement `applicable?/1` and `generate_forms/1`.

---

## Acceptance Criteria

1. `Ohmyword.Linguistics.Inflector` behaviour exists with two callbacks
2. `Dispatcher.inflect/1` routes to stub and returns `[{term, "base"}]`
3. `CacheManager.regenerate_word/1` creates search_terms with `source: :engine`
4. Locked entries survive regeneration
5. All tests pass
6. No changes to existing schemas or migrations required

---

## Do NOT

- Implement real inflection logic (that's Phase 2)
- Modify the Word or SearchTerm schemas
- Change existing seed data or migrations
- Create the Nouns/Verbs/Adjectives modules (parallel agents do this)
