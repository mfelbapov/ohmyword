defmodule Ohmyword.Linguistics.InflectorValidationTest do
  @moduledoc """
  Validates the inflection engine against seed data.

  The vocabulary_seed.json contains hand-curated forms that serve as
  the expected output. This test suite runs the engine and compares
  results to catch:
  - Missing forms (engine doesn't generate a form that seed has)
  - Wrong forms (engine generates different form than seed)
  - Extra forms (engine generates forms not in seed - informational)
  """

  use ExUnit.Case, async: true

  alias Ohmyword.Linguistics.Validator

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

  defp validate_words(entries, pos_label) do
    results =
      entries
      |> Enum.map(&Validator.validate/1)
      |> Enum.reject(& &1.passed)

    if results != [] do
      report = format_validation_report(results, pos_label)
      flunk(report)
    end
  end

  defp format_validation_report(results, pos_label) do
    header = "\n=== Inflector validation failed for #{pos_label}s ===\n"

    details =
      results
      |> Enum.map(&("  " <> Validator.format_result(&1)))
      |> Enum.join("\n")

    summary = "\nTotal: #{length(results)} word(s) with discrepancies"

    header <> details <> summary
  end
end
