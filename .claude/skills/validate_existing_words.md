# Skill: Validate Existing Words

## When to Use

When the user asks to validate existing words in the vocabulary seed against the inflection engine, audit engine accuracy, or find discrepancies between seed forms and engine output.

## Critical Constraint

**`priv/repo/vocabulary_seed.json` is READ-ONLY.** Never modify existing entries. This skill only reads seed data and writes discrepancies to `docs/existing_words_to check.md`.

## Serbian Ekavski Compliance

When reviewing discrepancies, also check that seed words conform to the Serbian ekavski standard:

1. **Jat reflex (ekavski)**: The word and ALL its inflected forms must use ekavski (e), never ijekavski (ije/je).
   - Correct: mleko, dete, reka, lepo, pesma, cvet, beo, delo, vera, vreme
   - Wrong: mlijeko, dijete, rijeka, lijepo, pjesma, cvijet, bijel, djelo, vjera, vrijeme

2. **Serbian lexicon**: The word must be standard Serbian vocabulary, not Croatian, Bosnian, or Montenegrin specific.
   - so (not sol), sto (not stol), hleb (not kruh), voz (not vlak)
   - vazduh (not zrak), hiljada (not tisuća), pozorište (not kazalište)
   - fudbal (not nogomet), hemija (not kemija), istorija (not povijest)
   - tačka (not točka), uslov (not uvjet), opština (not općina)
   - bezbedan (not siguran in Croatian sense), saobraćaj (not promet)

3. **Form-level check**: All inflected forms (both seed and engine) must maintain ekavski throughout. For example, the genitive of "mleko" is "mleka" (not "mlijeka"), the plural of "dete" is "deca" (not "djeca").

**If a word fails this check**: flag it in `docs/existing_words_to check.md` with the reason "Non-ekavski or non-Serbian lexeme" and suggest the correct ekavski equivalent.

## Background

The seed contains 521 words, all with `forms` arrays containing LLM-verified reference forms. Validation is fully automated — the script loads every word, runs the engine, and compares forms against the seed. Discrepancies are appended to `docs/existing_words_to check.md`.

---

## Running Validation

Use this flow for bulk validation of all words in the seed.

### Running the Script

Create and run this as a `mix run` script. It loads the seed, filters words with forms, runs the engine, and writes discrepancies to `docs/existing_words_to check.md`.

```elixir
# validate_existing_words.exs — run with: mix run validate_existing_words.exs
#
# Compares seed forms against engine output for all words that have
# a `forms` array in vocabulary_seed.json. Appends discrepancies
# to docs/existing_words_to check.md.

alias Ohmyword.Vocabulary.Word
alias Ohmyword.Linguistics.Dispatcher

seed_file = Path.join(:code.priv_dir(:ohmyword), "repo/vocabulary_seed.json")
output_file = "docs/existing_words_to check.md"

seed_data =
  seed_file
  |> File.read!()
  |> Jason.decode!()

# Only words that have forms arrays
words_with_forms = Enum.filter(seed_data, fn entry -> is_list(entry["forms"]) and entry["forms"] != [] end)

maybe_atom = fn
  nil -> nil
  val when is_binary(val) -> String.to_existing_atom(val)
end

build_word_struct = fn entry ->
  %Word{
    term: entry["term"],
    translation: entry["translation"],
    part_of_speech: String.to_existing_atom(entry["part_of_speech"]),
    gender: maybe_atom.(entry["gender"]),
    animate: entry["animate"],
    declension_class: entry["declension_class"],
    verb_aspect: maybe_atom.(entry["verb_aspect"]),
    conjugation_class: entry["conjugation_class"],
    reflexive: entry["reflexive"],
    grammar_metadata: entry["grammar_metadata"] || %{}
  }
end

normalize_forms = fn forms ->
  forms
  |> Enum.map(fn %{"term" => term, "form_tag" => tag} ->
    {String.downcase(term), String.downcase(tag)}
  end)
  |> Enum.sort()
end

run_engine = fn word ->
  word
  |> Dispatcher.inflect()
  |> Enum.map(fn {term, tag} -> {String.downcase(term), String.downcase(tag)} end)
  |> Enum.sort()
end

find_missing = fn expected, engine ->
  expected_tags = MapSet.new(expected, fn {_, tag} -> tag end)
  engine_tags = MapSet.new(engine, fn {_, tag} -> tag end)
  missing_tags = MapSet.difference(expected_tags, engine_tags)
  Enum.filter(expected, fn {_, tag} -> tag in missing_tags end)
end

find_wrong = fn expected, engine ->
  expected_map = Map.new(expected, fn {term, tag} -> {tag, term} end)
  engine_map = Map.new(engine, fn {term, tag} -> {tag, term} end)

  expected_map
  |> Enum.filter(fn {tag, exp_term} ->
    case Map.get(engine_map, tag) do
      nil -> false
      ^exp_term -> false
      _different -> true
    end
  end)
  |> Enum.map(fn {tag, exp_term} -> {tag, exp_term, Map.get(engine_map, tag)} end)
end

find_extra = fn expected, engine ->
  expected_tags = MapSet.new(expected, fn {_, tag} -> tag end)
  engine_tags = MapSet.new(engine, fn {_, tag} -> tag end)
  extra_tags = MapSet.difference(engine_tags, expected_tags)
  Enum.filter(engine, fn {_, tag} -> tag in extra_tags end)
end

# Process all words with forms
results =
  Enum.map(words_with_forms, fn entry ->
    word = build_word_struct.(entry)
    expected = normalize_forms.(entry["forms"])
    engine = run_engine.(word)

    %{
      term: entry["term"],
      pos: entry["part_of_speech"],
      gender: entry["gender"],
      missing: find_missing.(expected, engine),
      wrong: find_wrong.(expected, engine),
      extra: find_extra.(expected, engine)
    }
  end)

# Filter to only discrepancies (missing or wrong forms)
discrepancies = Enum.reject(results, fn r -> r.missing == [] and r.wrong == [] end)

IO.puts("Processed #{length(words_with_forms)} words with forms.")
IO.puts("Found #{length(discrepancies)} word(s) with discrepancies.")

if discrepancies != [] do
  markdown =
    Enum.map_join(discrepancies, "\n", fn r ->
      header =
        case r.gender do
          nil -> "## #{r.term} (#{r.pos})"
          g -> "## #{r.term} (#{r.pos}, #{g})"
        end

      reason_parts = []
      reason_parts = if r.wrong != [], do: reason_parts ++ ["#{length(r.wrong)} mismatched form(s)"], else: reason_parts
      reason_parts = if r.missing != [], do: reason_parts ++ ["#{length(r.missing)} missing from engine"], else: reason_parts
      reason = Enum.join(reason_parts, "; ")

      sections = [header, "", "**Reason:** #{reason}", ""]

      sections =
        if r.wrong != [] do
          rows =
            Enum.map_join(r.wrong, "\n", fn {tag, exp, eng} ->
              "| #{tag} | #{exp} | #{eng} |"
            end)

          sections ++ [
            "### Mismatched Forms (Seed vs Engine)",
            "| Form Tag | Seed | Engine |",
            "|---|---|---|",
            rows,
            ""
          ]
        else
          sections
        end

      sections =
        if r.missing != [] do
          rows =
            Enum.map_join(r.missing, "\n", fn {term, tag} ->
              "| #{tag} | Seed only | #{term} |"
            end)

          sections ++ [
            "### Missing Forms (not generated by engine)",
            "| Form Tag | Present In | Value |",
            "|---|---|---|",
            rows,
            ""
          ]
        else
          sections
        end

      sections =
        if r.extra != [] do
          rows =
            Enum.map_join(r.extra, "\n", fn {term, tag} ->
              "| #{tag} | Engine only | #{term} |"
            end)

          sections ++ [
            "### Extra Forms (engine generates, seed lacks — informational)",
            "| Form Tag | Present In | Value |",
            "|---|---|---|",
            rows,
            ""
          ]
        else
          sections
        end

      Enum.join(sections, "\n")
    end)

  # Append to existing file (or create it)
  preamble =
    if File.exists?(output_file) and File.read!(output_file) |> String.trim() != "" do
      "\n"
    else
      "# Existing Words to Check\n\nDiscrepancies between seed forms and engine output.\n\n"
    end

  File.write!(output_file, preamble <> markdown <> "\n", [:append])
  IO.puts("Appended discrepancies to #{output_file}")
else
  IO.puts("No discrepancies found — all seed forms match engine output.")
end
```

### How to Run

```bash
mix run validate_existing_words.exs
```

The script:
1. Loads `priv/repo/vocabulary_seed.json`
2. Filters to words with `forms` arrays (all 521 words)
3. For each word: builds a `Word` struct, runs `Dispatcher.inflect/1`, compares forms
4. Appends discrepancies to `docs/existing_words_to check.md`
5. Prints a summary to stdout

### Interpreting Results

- **Mismatched**: Same form tag, different form string — one of them is wrong (needs human review)
- **Missing from engine**: Seed has a form the engine doesn't generate — engine gap
- **Extra from engine**: Engine generates a form not in seed — usually informational (seed was incomplete)

> [!NOTE]
> If a word has massive discrepancies or the engine produces wild results, check if the seed `term` itself is a valid dictionary form (e.g., nominative singular vs plural). If invalid, flag it as "Invalid seed term".

---

## Output Format for `docs/existing_words_to check.md`

Discrepancies are appended to this file using the following format:

```markdown
# Existing Words to Check

Discrepancies between seed forms and engine output.

## kuća (noun, feminine)

**Reason:** 1 mismatched form(s); 2 missing from engine

### Mismatched Forms (Seed vs Engine)
| Form Tag | Seed | Engine |
|---|---|---|
| gen_pl | kuća | kućā |

### Missing Forms (not generated by engine)
| Form Tag | Present In | Value |
|---|---|---|
| voc_sg | Seed only | kućo |

### Extra Forms (engine generates, seed lacks — informational)
| Form Tag | Present In | Value |
|---|---|---|
| loc_pl | Engine only | kućama |

## trčati (verb)

**Reason:** 2 mismatched form(s)

### Mismatched Forms (Seed vs Engine)
| Form Tag | Seed | Engine |
|---|---|---|
| pres_1sg | trčim | trcim |
| imp_2sg | trči | trci |
```

---

## Notes

- **Seed is read-only.** Never modify `priv/repo/vocabulary_seed.json` via this skill. To fix words, use the `adding_new_word` skill or edit the seed separately.
- **The inline script reuses patterns from `inflector_validation_test.exs`** — same `build_word_struct`, comparison logic, and form normalization.
- **For invariable words** (prepositions, conjunctions, interjections, particles): the engine should return `[{"term", "invariable"}]`. These are trivially validated.
- **Adverbs with comparison:** Some adverbs also have `comparative` and `superlative` forms beyond the base `invariable` tag.
- **`declension_class` values** in the seed use both formats (`a-stem` and `a_stem`). The engine/struct accepts both — don't normalize when building structs.
