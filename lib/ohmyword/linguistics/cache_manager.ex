defmodule Ohmyword.Linguistics.CacheManager do
  @moduledoc """
  Handles regenerating `search_terms` from the inflection rule engine.

  The CacheManager coordinates between the Dispatcher (which generates forms)
  and the database (where SearchTerms are stored). It preserves manually
  locked entries while regenerating engine-generated forms.
  """

  import Ecto.Query

  alias Ohmyword.Repo
  alias Ohmyword.Vocabulary.Word
  alias Ohmyword.Search.SearchTerm
  alias Ohmyword.Linguistics.Dispatcher
  alias Ohmyword.Utils.Transliteration

  @doc """
  Regenerates search_terms for all vocabulary words.

  Streams through all words and regenerates their search_terms.
  Returns a summary of the operation.

  ## Examples

      iex> CacheManager.regenerate_all()
      {:ok, %{words: 150, forms: 1200}}
  """
  @spec regenerate_all() :: {:ok, %{words: non_neg_integer(), forms: non_neg_integer()}}
  def regenerate_all do
    Repo.transaction(fn ->
      Word
      |> Repo.stream()
      |> Enum.reduce(%{words: 0, forms: 0}, fn word, acc ->
        # Call the internal regeneration logic directly to avoid nested transactions
        delete_unlocked_terms(word.id)
        forms = Dispatcher.inflect(word)
        count = insert_forms(word.id, forms)

        %{words: acc.words + 1, forms: acc.forms + count}
      end)
    end)
  end

  @doc """
  Regenerates search_terms for a single word.

  Accepts either a word ID (integer or binary) or a Word struct.
  Preserves entries with `locked: true`.

  ## Examples

      iex> CacheManager.regenerate_word(123)
      {:ok, 1}

      iex> CacheManager.regenerate_word(%Word{id: 123, term: "pas"})
      {:ok, 1}

      iex> CacheManager.regenerate_word(999999)
      {:error, :not_found}
  """
  @spec regenerate_word(%Word{} | integer() | binary()) ::
          {:ok, non_neg_integer()} | {:error, :not_found | term()}
  def regenerate_word(%Word{} = word) do
    Repo.transaction(fn ->
      # Delete existing unlocked engine-generated terms
      delete_unlocked_terms(word.id)

      # Generate new forms
      forms = Dispatcher.inflect(word)

      # Insert new search terms
      insert_forms(word.id, forms)
    end)
  end

  def regenerate_word(word_id) when is_integer(word_id) or is_binary(word_id) do
    case Repo.get(Word, word_id) do
      nil -> {:error, :not_found}
      word -> regenerate_word(word)
    end
  end

  # Delete all unlocked search_terms for a word
  defp delete_unlocked_terms(word_id) do
    from(st in SearchTerm,
      where: st.word_id == ^word_id and st.locked == false
    )
    |> Repo.delete_all()
  end

  # Insert new search terms from generated forms
  defp insert_forms(word_id, forms) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      Enum.map(forms, fn {form, form_tag} ->
        %{
          term: form |> Transliteration.strip_diacritics() |> String.downcase(),
          display_form: String.downcase(form),
          form_tag: String.downcase(form_tag),
          word_id: word_id,
          source: :engine,
          locked: false,
          inserted_at: now,
          updated_at: now
        }
      end)

    case entries do
      [] ->
        0

      entries ->
        {count, _} =
          Repo.insert_all(SearchTerm, entries,
            on_conflict: :nothing,
            conflict_target: [:term, :word_id, :form_tag]
          )

        count
    end
  end
end
