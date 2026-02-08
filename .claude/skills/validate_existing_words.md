# Skill: Validate Existing Words

## When to Use

When the user asks to validate existing words in the vocabulary seed against the inflection engine, audit engine accuracy, or find discrepancies between seed forms and engine output.

## Critical Constraint

**`priv/repo/vocabulary_seed.json` is READ-ONLY.** Never modify existing entries. This skill only reads seed data and writes discrepancies to `docs/existing_words_to check.md`.

## Background

The seed contains 521 words total:
- ~340 words **with** `forms` arrays — these have LLM-generated reference forms that can be compared automatically
- ~181 words **without** `forms` arrays — these need manual (LLM-assisted) form generation before comparison

Both flows append discrepancies to the same output file: `docs/existing_words_to check.md`.

---

## Flow A — Automated Comparison (words WITH seed forms)

Use this flow for bulk validation of words that already have `forms` arrays in the seed.

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
2. Filters to words with `forms` arrays (~340 words)
3. For each word: builds a `Word` struct, runs `Dispatcher.inflect/1`, compares forms
4. Appends discrepancies to `docs/existing_words_to check.md`
5. Prints a summary to stdout

### Interpreting Results

- **Mismatched**: Same form tag, different form string — one of them is wrong (needs human review)
- **Missing from engine**: Seed has a form the engine doesn't generate — engine gap
- **Extra from engine**: Engine generates a form not in seed — usually informational (seed was incomplete)

---

## Flow B — LLM-Assisted Comparison (words WITHOUT seed forms)

Use this flow for words that lack `forms` arrays in the seed. Process in batches of ~10-20 words.

### Step 1 — Load a Batch

In IEx or via a script, list words without forms:

```elixir
seed_data =
  :code.priv_dir(:ohmyword)
  |> Path.join("repo/vocabulary_seed.json")
  |> File.read!()
  |> Jason.decode!()

no_forms = Enum.filter(seed_data, fn e -> is_nil(e["forms"]) or e["forms"] == [] end)
IO.puts("Total words without forms: #{length(no_forms)}")

# Show a batch (adjust offset for subsequent batches)
batch = Enum.slice(no_forms, 0, 20)
Enum.each(batch, fn e ->
  IO.puts("#{e["term"]} (#{e["part_of_speech"]}, #{e["gender"] || "—"})")
end)
```

**Note:** Many of the ~181 words without forms are invariables (prepositions, conjunctions, interjections, particles). These are trivial — the engine should return a single `{"term", "invariable"}` form. Focus manual effort on nouns, verbs, adjectives, and pronouns.

### Step 2 — Claude Generates Expected Forms

For each word in the batch, you (Claude) generate all expected inflected forms using Serbian grammar knowledge. Use the same form tags listed in the `adding_new_word` skill:

- **Nouns** (14 forms): `nom_sg`, `gen_sg`, `dat_sg`, `acc_sg`, `voc_sg`, `ins_sg`, `loc_sg`, `nom_pl`, `gen_pl`, `dat_pl`, `acc_pl`, `voc_pl`, `ins_pl`, `loc_pl`
- **Verbs** (24 forms): `infinitive`, `pres_1sg`–`pres_3pl`, `past_m_sg`–`past_n_pl`, `imp_2sg`, `imp_1pl`, `imp_2pl`, `pp_m_sg`–`pp_n_pl`, `pres_adv_participle`, `past_adv_participle`
- **Adjectives** (up to 84 forms): `{indef|def}_{case}_{number}_{gender}`
- **Invariables**: single `invariable` form (plus optional `comparative`, `superlative` for adverbs)
- **Pronouns**: paradigm-dependent `_sg`/`_pl` tags
- **Numerals**: ordinals get adjective-like forms; cardinals 5+ get single `base` form

### Step 3 — Run Engine and Compare

For each word in the batch, run the engine:

```elixir
word = %Ohmyword.Vocabulary.Word{
  term: "kuća",
  part_of_speech: :noun,
  gender: :feminine,
  declension_class: "a_stem",
  animate: false,
  grammar_metadata: %{}
}

engine_forms = Ohmyword.Linguistics.Dispatcher.inflect(word)
IO.inspect(engine_forms, label: "Engine forms")
```

Compare Claude's expected forms against engine output. Look for:
- Missing form tags (expected but not generated)
- Wrong form strings (same tag, different string)
- Extra form tags (generated but not expected)

### Step 4 — Log Discrepancies

Append any discrepancies to `docs/existing_words_to check.md` using the same output format as Flow A.

### Step 5 — Next Batch

Move to the next batch of ~20 words. Track which offset you're at:

```elixir
batch = Enum.slice(no_forms, 20, 20)  # second batch
batch = Enum.slice(no_forms, 40, 20)  # third batch
# ... and so on
```

---

## Output Format for `docs/existing_words_to check.md`

All discrepancies (from both flows) are appended to the same file using this format:

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
- **Both flows append to the same file.** `docs/existing_words_to check.md` accumulates all discrepancies.
- **The inline script reuses patterns from `inflector_validation_test.exs`** — same `build_word_struct`, comparison logic, and form normalization.
- **For invariable words** (prepositions, conjunctions, interjections, particles): the engine should return `[{"term", "invariable"}]`. These are trivially validated — batch them together in Flow B.
- **Adverbs with comparison:** Some adverbs also have `comparative` and `superlative` forms beyond the base `invariable` tag.
- **`declension_class` values** in the seed use both formats (`a-stem` and `a_stem`). The engine/struct accepts both — don't normalize when building structs.
