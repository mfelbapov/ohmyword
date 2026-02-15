# Usage: mix run scripts/batch_add_words.exs <input_json_file>
#
# Reads a JSON array of word entries, validates each against the engine,
# and merges passing words into vocabulary_seed.json.
# Failed words are logged to docs/new_words_to_check.md.

alias Ohmyword.Linguistics.Validator
alias Ohmyword.Linguistics.Dispatcher

[input_file | _] = System.argv()

seed_path = "priv/repo/vocabulary_seed.json"
fail_path = "docs/new_words_to_check.md"

# Load existing seed to check duplicates
existing_seed = seed_path |> File.read!() |> Jason.decode!()
existing_terms = MapSet.new(existing_seed, & &1["term"])

# Load new entries
entries = input_file |> File.read!() |> Jason.decode!()

IO.puts("Processing #{length(entries)} entries...")
IO.puts("Existing seed has #{MapSet.size(existing_terms)} unique terms.\n")

{passed, failed, skipped} =
  Enum.reduce(entries, {[], [], []}, fn entry, {passed, failed, skipped} ->
    term = entry["term"]

    cond do
      MapSet.member?(existing_terms, term) ->
        IO.puts("SKIP (duplicate): #{term}")
        {passed, failed, [{entry, "duplicate"} | skipped]}

      entry["part_of_speech"] in ~w(adverb preposition conjunction interjection particle) and
          not Map.has_key?(entry, "forms") ->
        # Auto-generate form: adverbs use "base", others use "invariable"
        form_tag = if entry["part_of_speech"] == "adverb", do: "base", else: "invariable"
        entry = Map.put(entry, "forms", [%{"term" => term, "form_tag" => form_tag}])
        result = Validator.validate(entry)

        if result.passed do
          IO.puts("PASS: #{term} (#{entry["part_of_speech"]})")
          {[entry | passed], failed, skipped}
        else
          IO.puts("FAIL: #{term} — #{Validator.format_result(result)}")
          {passed, [{entry, result} | failed], skipped}
        end

      not Map.has_key?(entry, "forms") ->
        # Auto-generate forms from engine (for verbs and other POS without explicit forms)
        word = Validator.build_word_struct(entry)
        engine_forms = Dispatcher.inflect(word)
        forms = Enum.map(engine_forms, fn {t, tag} -> %{"term" => t, "form_tag" => tag} end)
        entry = Map.put(entry, "forms", forms)
        IO.puts("PASS: #{term} (#{entry["part_of_speech"]}) — #{length(forms)} engine forms")
        {[entry | passed], failed, skipped}

      true ->
        result = Validator.validate(entry)

        if result.passed do
          IO.puts("PASS: #{term} (#{entry["part_of_speech"]}) — #{result.expected_count} forms")
          {[entry | passed], failed, skipped}
        else
          IO.puts("FAIL: #{term}\n  #{Validator.format_result(result)}")
          {passed, [{entry, result} | failed], skipped}
        end
    end
  end)

passed = Enum.reverse(passed)
failed = Enum.reverse(failed)
skipped = Enum.reverse(skipped)

IO.puts("\n=== SUMMARY ===")
IO.puts("Passed: #{length(passed)}")
IO.puts("Failed: #{length(failed)}")
IO.puts("Skipped (duplicate): #{length(skipped)}")

# Merge passed into seed
if passed != [] do
  new_seed = existing_seed ++ passed
  File.write!(seed_path, Jason.encode!(new_seed, pretty: true))
  IO.puts("\nAdded #{length(passed)} words to #{seed_path}")
  IO.puts("New total: #{length(new_seed)} entries")
end

# Log failures
if failed != [] do
  fail_content =
    Enum.map_join(failed, "\n\n", fn {entry, result} ->
      "## #{entry["term"]} (#{entry["part_of_speech"]})\n\n" <>
        "**Validator output:**\n```\n#{Validator.format_result(result)}\n```"
    end)

  existing_fails = if File.exists?(fail_path), do: File.read!(fail_path), else: ""

  File.write!(fail_path, existing_fails <> "\n\n" <> fail_content)
  IO.puts("\nLogged #{length(failed)} failures to #{fail_path}")
end
