defmodule Ohmyword.Search do
  @moduledoc """
  The Search context.

  Provides lookup functionality for vocabulary words by any of their
  inflected forms (declensions, conjugations, etc.).
  """

  import Ecto.Query

  alias Ohmyword.Repo
  alias Ohmyword.Search.SearchTerm
  alias Ohmyword.Utils.Transliteration
  alias Ohmyword.Vocabulary.Word

  @doc """
  Looks up words by a search term.

  Tries Serbian search first (Latin/Cyrillic, diacritics-insensitive). If no
  Serbian results are found, falls back to English translation search.

  ## Examples

      iex> Search.lookup("psa")
      [%{word: %Word{term: "pas", ...}, matched_form: "psa", form_tag: "gen_sg"}]

      iex> Search.lookup("пса")  # Cyrillic input
      [%{word: %Word{term: "pas", ...}, matched_form: "psa", form_tag: "gen_sg"}]

      iex> Search.lookup("dog")  # English fallback
      [%{word: %Word{term: "pas", ...}, matched_form: "dog", form_tag: "translation"}]

      iex> Search.lookup("nonexistent")
      []
  """
  def lookup(query) when is_binary(query) do
    case lookup_serbian(query) do
      [] -> lookup_english(query)
      results -> results
    end
  end

  @doc """
  Returns the total number of search terms.
  """
  def count_search_terms do
    Repo.aggregate(SearchTerm, :count)
  end

  defp lookup_serbian(query) do
    normalized = normalize_query(query)

    SearchTerm
    |> where([st], st.term == ^normalized)
    |> preload(:word)
    |> Repo.all()
    |> Enum.map(fn search_term ->
      %{
        word: search_term.word,
        matched_form: search_term.display_form,
        form_tag: search_term.form_tag
      }
    end)
    |> Enum.group_by(& &1.word.id)
    |> Enum.map(fn {_word_id, results} ->
      Enum.find(results, hd(results), fn r -> r.matched_form == r.word.term end)
    end)
  end

  defp lookup_english(query) do
    lower_query = String.downcase(String.trim(query))

    Word
    |> where(
      [w],
      fragment("? = ANY(string_to_array(lower(?), ' '))", ^lower_query, w.translation)
    )
    |> Repo.all()
    |> Enum.map(fn word ->
      %{word: word, matched_form: word.translation, form_tag: "translation"}
    end)
    |> then(fn results ->
      # Also search alternative translations
      already_found_ids = MapSet.new(results, & &1.word.id)

      alt_results =
        Word
        |> where(
          [w],
          fragment(
            "EXISTS (SELECT 1 FROM unnest(?) AS t WHERE ? = ANY(string_to_array(lower(t), ' ')))",
            w.translations,
            ^lower_query
          )
        )
        |> Repo.all()
        |> Enum.reject(fn word -> MapSet.member?(already_found_ids, word.id) end)
        |> Enum.map(fn word ->
          matched = find_matching_translation(word.translations, lower_query)
          %{word: word, matched_form: matched, form_tag: "translation"}
        end)

      results ++ alt_results
    end)
  end

  defp find_matching_translation(translations, lower_query) do
    Enum.find(translations, hd(translations), fn t ->
      lower_query in String.split(String.downcase(t), " ")
    end)
  end

  # Normalizes search input: Cyrillic → Latin, strip diacritics, lowercase
  defp normalize_query(query) do
    query
    |> Transliteration.to_latin()
    |> Transliteration.strip_diacritics()
    |> String.downcase()
  end
end
