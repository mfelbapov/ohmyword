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

  @doc """
  Looks up words by a search term.

  The input is normalized: Cyrillic is converted to Latin, then lowercased.
  Returns all matching words with their form information.

  ## Examples

      iex> Search.lookup("psa")
      [%{word: %Word{term: "pas", ...}, matched_form: "psa", form_tag: "gen_sg"}]

      iex> Search.lookup("пса")  # Cyrillic input
      [%{word: %Word{term: "pas", ...}, matched_form: "psa", form_tag: "gen_sg"}]

      iex> Search.lookup("kosa")  # homograph
      [
        %{word: %Word{translation: "hair", ...}, matched_form: "kosa", form_tag: "nom_sg"},
        %{word: %Word{translation: "scythe", ...}, matched_form: "kosa", form_tag: "nom_sg"}
      ]

      iex> Search.lookup("nonexistent")
      []
  """
  def lookup(query) when is_binary(query) do
    normalized = normalize_query(query)

    SearchTerm
    |> where([st], st.term == ^normalized)
    |> preload(:word)
    |> Repo.all()
    |> Enum.map(fn search_term ->
      %{
        word: search_term.word,
        matched_form: search_term.term,
        form_tag: search_term.form_tag
      }
    end)
  end

  # Normalizes search input:
  # 1. Convert Cyrillic to Latin
  # 2. Lowercase
  defp normalize_query(query) do
    query
    |> Transliteration.to_latin()
    |> String.downcase()
  end
end
