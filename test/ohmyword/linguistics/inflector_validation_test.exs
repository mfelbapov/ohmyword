defmodule Ohmyword.Linguistics.InflectorValidationTest do
  @moduledoc """
  Validates the inflection engine against seed data.

  The vocabulary_seed.json contains hand-curated forms that serve as
  the expected output. This test suite runs the engine and compares
  results to catch:
  - Missing forms (engine doesn't generate a form that seed has)
  - Wrong forms (engine generates different form than seed)
  - Extra forms (engine generates forms not in seed - informational)

  These tests are EXCLUDED by default (in test_helper.exs) because they validate
  the inflection engine against hand-curated seed data, and the engine is still
  being developed. Failures here indicate gaps in the inflector rules, not bugs.

  ## Running these tests

      # Run only inflector validation tests
      mix test --include inflector_validation test/ohmyword/linguistics/inflector_validation_test.exs

      # Run all tests including validation
      mix test --include inflector_validation

  ## Test output

  - MISSING: Engine doesn't generate a form that seed has
  - WRONG: Engine generates different form than seed expects
  - EXTRA: Engine generates forms not in seed (informational only, not a failure)
  """

  use ExUnit.Case, async: true

  @moduletag :inflector_validation

  alias Ohmyword.Vocabulary.Word
  alias Ohmyword.Linguistics.Dispatcher

  @seed_file Path.join(:code.priv_dir(:ohmyword), "repo/vocabulary_seed.json")

  setup_all do
    seed_data =
      @seed_file
      |> File.read!()
      |> Jason.decode!()

    {:ok, seed_data: seed_data}
  end

  describe "inflector validation against seed data" do
    test "engine produces expected forms for nouns", %{seed_data: seed_data} do
      nouns = Enum.filter(seed_data, &(&1["part_of_speech"] == "noun"))
      validate_words(nouns, "noun")
    end

    test "engine produces expected forms for verbs", %{seed_data: seed_data} do
      verbs = Enum.filter(seed_data, &(&1["part_of_speech"] == "verb"))
      validate_words(verbs, "verb")
    end

    test "engine produces expected forms for adjectives", %{seed_data: seed_data} do
      adjectives = Enum.filter(seed_data, &(&1["part_of_speech"] == "adjective"))
      validate_words(adjectives, "adjective")
    end

    test "engine produces expected forms for pronouns", %{seed_data: seed_data} do
      pronouns = Enum.filter(seed_data, &(&1["part_of_speech"] == "pronoun"))
      validate_words(pronouns, "pronoun")
    end

    test "engine produces expected forms for other parts of speech", %{seed_data: seed_data} do
      other_pos = ["numeral", "preposition", "conjunction", "adverb", "particle"]

      others =
        Enum.filter(seed_data, fn entry ->
          entry["part_of_speech"] in other_pos
        end)

      validate_words(others, "other")
    end
  end

  describe "individual word validation (for debugging)" do
    @tag :skip
    test "validate specific word", %{seed_data: seed_data} do
      # Change this to debug a specific word
      word_term = "pas"

      entry = Enum.find(seed_data, &(&1["term"] == word_term))
      assert entry, "Word '#{word_term}' not found in seed data"

      result = validate_single_word(entry)
      IO.puts("\n#{format_validation_result(result)}")

      assert result.missing == [],
             "Missing forms for '#{word_term}': #{inspect(result.missing)}"

      assert result.wrong == [],
             "Wrong forms for '#{word_term}': #{inspect(result.wrong)}"
    end
  end

  # Validates a list of words and collects all discrepancies
  defp validate_words(entries, pos_label) do
    results =
      entries
      |> Enum.map(&validate_single_word/1)
      |> Enum.reject(&validation_passed?/1)

    if results != [] do
      report = format_validation_report(results, pos_label)
      flunk(report)
    end
  end

  # Validates a single word entry from seed data
  defp validate_single_word(entry) do
    word = build_word_struct(entry)
    expected_forms = normalize_forms(entry["forms"] || [])
    engine_forms = run_engine(word)

    %{
      term: entry["term"],
      part_of_speech: entry["part_of_speech"],
      missing: find_missing_forms(expected_forms, engine_forms),
      wrong: find_wrong_forms(expected_forms, engine_forms),
      extra: find_extra_forms(expected_forms, engine_forms),
      expected_count: length(expected_forms),
      engine_count: length(engine_forms)
    }
  end

  # Build a Word struct from seed entry (without DB)
  defp build_word_struct(entry) do
    %Word{
      term: entry["term"],
      translation: entry["translation"],
      part_of_speech: String.to_existing_atom(entry["part_of_speech"]),
      gender: maybe_atom(entry["gender"]),
      animate: entry["animate"],
      declension_class: entry["declension_class"],
      verb_aspect: maybe_atom(entry["verb_aspect"]),
      conjugation_class: entry["conjugation_class"],
      reflexive: entry["reflexive"],
      grammar_metadata: entry["grammar_metadata"] || %{}
    }
  end

  defp maybe_atom(nil), do: nil
  defp maybe_atom(val) when is_binary(val), do: String.to_existing_atom(val)

  # Normalize forms to a consistent format: [{term, form_tag}, ...]
  defp normalize_forms(forms) do
    forms
    |> Enum.map(fn %{"term" => term, "form_tag" => tag} ->
      {String.downcase(term), String.downcase(tag)}
    end)
    |> Enum.sort()
  end

  # Run the engine and get forms
  defp run_engine(word) do
    word
    |> Dispatcher.inflect()
    |> Enum.map(fn {term, tag} ->
      {String.downcase(term), String.downcase(tag)}
    end)
    |> Enum.sort()
  end

  # Forms in expected but not in engine (by form_tag)
  defp find_missing_forms(expected, engine) do
    expected_tags = MapSet.new(expected, fn {_, tag} -> tag end)
    engine_tags = MapSet.new(engine, fn {_, tag} -> tag end)

    missing_tags = MapSet.difference(expected_tags, engine_tags)

    Enum.filter(expected, fn {_, tag} -> tag in missing_tags end)
  end

  # Forms where engine has different term for same form_tag
  defp find_wrong_forms(expected, engine) do
    expected_map = Map.new(expected, fn {term, tag} -> {tag, term} end)
    engine_map = Map.new(engine, fn {term, tag} -> {tag, term} end)

    expected_map
    |> Enum.filter(fn {tag, expected_term} ->
      case Map.get(engine_map, tag) do
        nil -> false
        ^expected_term -> false
        _different -> true
      end
    end)
    |> Enum.map(fn {tag, expected_term} ->
      {tag, expected_term, Map.get(engine_map, tag)}
    end)
  end

  # Forms engine generates that aren't in expected
  defp find_extra_forms(expected, engine) do
    expected_tags = MapSet.new(expected, fn {_, tag} -> tag end)
    engine_tags = MapSet.new(engine, fn {_, tag} -> tag end)

    extra_tags = MapSet.difference(engine_tags, expected_tags)

    Enum.filter(engine, fn {_, tag} -> tag in extra_tags end)
  end

  defp validation_passed?(result) do
    result.missing == [] and result.wrong == []
  end

  defp format_validation_report(results, pos_label) do
    header = "\n=== Inflector validation failed for #{pos_label}s ===\n"

    details =
      results
      |> Enum.map(&format_validation_result/1)
      |> Enum.join("\n")

    summary = "\nTotal: #{length(results)} word(s) with discrepancies"

    header <> details <> summary
  end

  defp format_validation_result(result) do
    lines = ["  #{result.term} (#{result.part_of_speech}):"]

    lines =
      if result.missing != [] do
        missing_str =
          result.missing
          |> Enum.map(fn {term, tag} -> "#{tag}=#{term}" end)
          |> Enum.join(", ")

        lines ++ ["    MISSING: #{missing_str}"]
      else
        lines
      end

    lines =
      if result.wrong != [] do
        wrong_str =
          result.wrong
          |> Enum.map(fn {tag, expected, got} -> "#{tag}: expected '#{expected}', got '#{got}'" end)
          |> Enum.join(", ")

        lines ++ ["    WRONG: #{wrong_str}"]
      else
        lines
      end

    lines =
      if result.extra != [] do
        extra_str =
          result.extra
          |> Enum.map(fn {term, tag} -> "#{tag}=#{term}" end)
          |> Enum.join(", ")

        lines ++ ["    EXTRA (info): #{extra_str}"]
      else
        lines
      end

    Enum.join(lines, "\n")
  end
end
