defmodule Ohmyword.Linguistics.Helpers do
  @moduledoc """
  Shared helper functions used across multiple inflector modules.

  Consolidates phonological utilities (fleeting vowel removal, consonant/vowel
  checks) and the irregular-forms override pattern that was previously
  duplicated in Nouns, Adjectives, Verbs, and Numerals.
  """

  @doc """
  Removes the fleeting 'a' from a stem.

  Finds the rightmost 'a' that is surrounded by consonants and removes it.

  ## Examples

      iex> Helpers.remove_fleeting_a("pas")
      "ps"

      iex> Helpers.remove_fleeting_a("vrabac")
      "vrabc"

      iex> Helpers.remove_fleeting_a("dobar")
      "dobr"
  """
  def remove_fleeting_a(term) do
    graphemes = String.graphemes(term)

    if length(graphemes) < 3 do
      term
    else
      find_and_remove_fleeting_a(graphemes)
    end
  end

  @doc """
  Returns `true` if the given single-character binary is a consonant.
  """
  def is_consonant?(char) when is_binary(char) do
    char not in ~w(a e i o u)
  end

  @doc """
  Returns `true` if the given single-character binary is a vowel.
  """
  def is_vowel?(char) when is_binary(char) do
    char in ~w(a e i o u)
  end

  @doc """
  Applies irregular form overrides from metadata to a list of `{form, tag}` tuples.

  Looks up `metadata["irregular_forms"]` and replaces any matching tags.

  ## Examples

      iex> forms = [{"psa", "gen_sg"}, {"psu", "dat_sg"}]
      iex> metadata = %{"irregular_forms" => %{"gen_sg" => "Pesa"}}
      iex> Helpers.apply_overrides(forms, metadata)
      [{"pesa", "gen_sg"}, {"psu", "dat_sg"}]
  """
  def apply_overrides(forms, metadata) do
    irregular_forms = metadata["irregular_forms"] || %{}

    Enum.map(forms, fn {form, tag} ->
      case Map.get(irregular_forms, tag) do
        nil -> {form, tag}
        override -> {String.downcase(override), tag}
      end
    end)
  end

  # --- Private helpers ---

  defp find_and_remove_fleeting_a(graphemes) do
    indexed = Enum.with_index(graphemes)

    # Find the rightmost 'a' that is surrounded by consonants
    result =
      indexed
      |> Enum.reverse()
      |> Enum.find(fn {char, idx} ->
        char == "a" && idx > 0 && idx < length(graphemes) - 1 &&
          is_consonant?(Enum.at(graphemes, idx - 1)) &&
          is_consonant?(Enum.at(graphemes, idx + 1))
      end)

    case result do
      {_, idx} ->
        graphemes
        |> List.delete_at(idx)
        |> Enum.join()

      nil ->
        Enum.join(graphemes)
    end
  end
end
