defmodule Ohmyword.Linguistics.Validator do
  @moduledoc """
  Validates inflected forms against the engine output.

  Takes a seed-format entry (string-keyed map with `"forms"` key), builds a
  Word struct, runs it through the Dispatcher, and compares the expected forms
  with the engine output.

  ## Usage

      entry = %{
        "term" => "kuća",
        "part_of_speech" => "noun",
        "gender" => "feminine",
        "declension_class" => "a_stem",
        "forms" => [%{"term" => "kuća", "form_tag" => "nom_sg"}, ...]
      }

      result = Validator.validate(entry)
      IO.puts(Validator.format_result(result))
  """

  alias Ohmyword.Vocabulary.Word
  alias Ohmyword.Linguistics.Dispatcher

  @doc """
  Validates a seed entry's forms against the engine output.

  Takes a string-keyed map (seed JSON format) with a `"forms"` key containing
  expected forms. Returns a result map with `:passed`, `:missing`, `:wrong`,
  and `:extra` keys.

  ## Examples

      iex> result = Validator.validate(%{"term" => "i", "part_of_speech" => "conjunction", "forms" => [%{"term" => "i", "form_tag" => "invariable"}]})
      iex> result.passed
      true
  """
  @spec validate(map()) :: map()
  def validate(entry) do
    word = build_word_struct(entry)
    expected = normalize_seed_forms(entry["forms"] || [])
    engine = normalize_engine_forms(Dispatcher.inflect(word))

    %{missing: missing, wrong: wrong, extra: extra} = compare_forms(expected, engine)

    %{
      term: entry["term"],
      part_of_speech: entry["part_of_speech"],
      passed: missing == [] and wrong == [],
      missing: missing,
      wrong: wrong,
      extra: extra,
      expected_count: length(expected),
      engine_count: length(engine)
    }
  end

  @doc """
  Builds a Word struct from a string-keyed seed entry without touching the DB.

  ## Examples

      iex> word = Validator.build_word_struct(%{"term" => "pas", "part_of_speech" => "noun", "gender" => "masculine"})
      iex> word.term
      "pas"
      iex> word.part_of_speech
      :noun
  """
  @spec build_word_struct(map()) :: %Word{}
  def build_word_struct(entry) do
    %Word{
      term: entry["term"],
      translation: entry["translation"],
      part_of_speech: String.to_atom(entry["part_of_speech"]),
      gender: maybe_atom(entry["gender"]),
      animate: entry["animate"],
      declension_class: entry["declension_class"],
      verb_aspect: maybe_atom(entry["verb_aspect"]),
      conjugation_class: entry["conjugation_class"],
      reflexive: entry["reflexive"],
      grammar_metadata: entry["grammar_metadata"] || %{}
    }
  end

  @doc """
  Compares expected and engine form lists.

  Both inputs should be sorted lists of `{term, form_tag}` tuples (already
  normalized via `normalize_seed_forms/1` or `normalize_engine_forms/1`).

  Returns `%{missing: [...], wrong: [...], extra: [...]}`.

  - `:missing` — `{term, tag}` tuples in expected but whose tag is absent from engine
  - `:wrong` — `{tag, expected_term, engine_term}` triples where both have the tag but differ
  - `:extra` — `{term, tag}` tuples in engine but whose tag is absent from expected
  """
  @spec compare_forms(list(), list()) :: map()
  def compare_forms(expected, engine) do
    %{
      missing: find_missing_forms(expected, engine),
      wrong: find_wrong_forms(expected, engine),
      extra: find_extra_forms(expected, engine)
    }
  end

  @doc """
  Formats a validation result as a human-readable string.

  ## Examples

      iex> Validator.format_result(%{term: "i", part_of_speech: "conjunction", passed: true, missing: [], wrong: [], extra: [], expected_count: 1, engine_count: 1})
      "i (conjunction): PASS (1 forms)"
  """
  @spec format_result(map()) :: String.t()
  def format_result(%{passed: true} = result) do
    "#{result.term} (#{result.part_of_speech}): PASS (#{result.expected_count} forms)"
  end

  def format_result(result) do
    lines = ["#{result.term} (#{result.part_of_speech}): FAIL"]

    lines =
      if result.missing != [] do
        missing_str =
          result.missing
          |> Enum.map(fn {term, tag} -> "#{tag}=#{term}" end)
          |> Enum.join(", ")

        lines ++ ["  MISSING: #{missing_str}"]
      else
        lines
      end

    lines =
      if result.wrong != [] do
        wrong_str =
          result.wrong
          |> Enum.map(fn {tag, expected, got} ->
            "#{tag}: expected '#{expected}', got '#{got}'"
          end)
          |> Enum.join(", ")

        lines ++ ["  WRONG: #{wrong_str}"]
      else
        lines
      end

    lines =
      if result.extra != [] do
        extra_str =
          result.extra
          |> Enum.map(fn {term, tag} -> "#{tag}=#{term}" end)
          |> Enum.join(", ")

        lines ++ ["  EXTRA (info): #{extra_str}"]
      else
        lines
      end

    Enum.join(lines, "\n")
  end

  # Normalize seed forms (string-keyed maps) to sorted [{term, form_tag}] tuples
  defp normalize_seed_forms(forms) do
    forms
    |> Enum.map(fn %{"term" => term, "form_tag" => tag} ->
      {String.downcase(term), String.downcase(tag)}
    end)
    |> Enum.sort()
  end

  # Normalize engine forms (already {term, tag} tuples) to sorted lowercase
  defp normalize_engine_forms(forms) do
    forms
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

  defp maybe_atom(nil), do: nil
  defp maybe_atom(val) when is_binary(val), do: String.to_atom(val)
end
