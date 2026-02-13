defmodule Ohmyword.Vocabulary.WordImporter do
  @moduledoc """
  Imports a word from a seed-format map (string keys).
  Creates the Word record, inserts locked seed forms, and runs the engine to fill gaps.
  """

  alias Ohmyword.Repo
  alias Ohmyword.Vocabulary.Word
  alias Ohmyword.Search.SearchTerm
  alias Ohmyword.Linguistics.CacheManager
  alias Ohmyword.Utils.Transliteration

  @doc """
  Imports a word from a seed-format map with string keys.

  Returns `{:ok, word}` or `{:error, changeset}`.
  """
  def import_from_seed(entry) do
    {forms, entry} = Map.pop(entry, "forms", [])
    {_aspect_pair_term, entry} = Map.pop(entry, "aspect_pair_term")

    attrs = atomize_keys(entry)

    case %Word{} |> Word.changeset(attrs) |> Repo.insert() do
      {:ok, word} ->
        Enum.each(forms, fn form -> insert_locked_form(word, form) end)
        CacheManager.regenerate_word(word)
        {:ok, word}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp insert_locked_form(word, %{"term" => term, "form_tag" => form_tag}) do
    %SearchTerm{}
    |> SearchTerm.changeset(%{
      term: term |> Transliteration.strip_diacritics() |> String.downcase(),
      display_form: String.downcase(term),
      form_tag: String.downcase(form_tag),
      word_id: word.id,
      source: :seed,
      locked: true
    })
    |> Repo.insert()
  end

  defp atomize_keys(map) do
    Map.new(map, fn {k, v} ->
      key = String.to_existing_atom(k)
      value = convert_enum_value(key, v)
      {key, value}
    end)
  rescue
    ArgumentError -> map
  end

  defp convert_enum_value(:part_of_speech, v) when is_binary(v), do: String.to_existing_atom(v)
  defp convert_enum_value(:gender, v) when is_binary(v), do: String.to_existing_atom(v)
  defp convert_enum_value(:verb_aspect, v) when is_binary(v), do: String.to_existing_atom(v)
  defp convert_enum_value(_, v), do: v
end
