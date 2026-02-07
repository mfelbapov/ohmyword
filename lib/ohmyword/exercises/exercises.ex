defmodule Ohmyword.Exercises do
  @moduledoc """
  The Exercises context.

  Provides the public API for exercise operations including
  listing sentences and checking user answers.
  """

  import Ecto.Query

  alias Ohmyword.Repo
  alias Ohmyword.Exercises.Sentence
  alias Ohmyword.Search.SearchTerm
  alias Ohmyword.Utils.Transliteration

  @doc """
  Lists sentences with optional filters.

  ## Options

    * `:word_id` - Filter by word ID
    * `:part_of_speech` - Filter by the word's part of speech

  ## Examples

      iex> Exercises.list_sentences()
      [%Sentence{}, ...]

      iex> Exercises.list_sentences(part_of_speech: :noun)
      [%Sentence{}, ...]
  """
  def list_sentences(opts \\ []) do
    Sentence
    |> apply_filters(opts)
    |> Repo.all()
    |> Repo.preload(:word)
  end

  @doc """
  Gets a sentence by ID.

  Raises `Ecto.NoResultsError` if the sentence does not exist.

  ## Examples

      iex> Exercises.get_sentence!(123)
      %Sentence{}

      iex> Exercises.get_sentence!(0)
      ** (Ecto.NoResultsError)
  """
  def get_sentence!(id) do
    Sentence
    |> Repo.get!(id)
    |> Repo.preload(:word)
  end

  @doc """
  Gets a random sentence, optionally filtered by part of speech.

  Returns `nil` if no sentences match the criteria.

  ## Options

    * `:part_of_speech` - Filter by the word's part of speech

  ## Examples

      iex> Exercises.get_random_sentence()
      %Sentence{}

      iex> Exercises.get_random_sentence(part_of_speech: :noun)
      %Sentence{}
  """
  def get_random_sentence(opts \\ []) do
    Sentence
    |> apply_filters(opts)
    |> order_by(fragment("RANDOM()"))
    |> limit(1)
    |> Repo.one()
    |> maybe_preload_word()
  end

  @doc """
  Creates a sentence.

  ## Examples

      iex> Exercises.create_sentence(%{text: "Vidim {blank}.", ...})
      {:ok, %Sentence{}}

      iex> Exercises.create_sentence(%{invalid: "attrs"})
      {:error, %Ecto.Changeset{}}
  """
  def create_sentence(attrs) do
    %Sentence{}
    |> Sentence.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sentence.

  ## Examples

      iex> Exercises.update_sentence(sentence, %{translation: "new"})
      {:ok, %Sentence{}}
  """
  def update_sentence(%Sentence{} = sentence, attrs) do
    sentence
    |> Sentence.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a sentence.

  ## Examples

      iex> Exercises.delete_sentence(sentence)
      {:ok, %Sentence{}}
  """
  def delete_sentence(%Sentence{} = sentence) do
    Repo.delete(sentence)
  end

  @doc """
  Checks the user's answer against the expected forms for the sentence.

  Returns `{:correct, matched_form}` if the normalized input matches any
  expected form, or `{:incorrect, expected_forms}` otherwise.

  Answer matching is diacritic-insensitive and case-insensitive.

  ## Examples

      iex> Exercises.check_answer(sentence, "psa")
      {:correct, "psa"}

      iex> Exercises.check_answer(sentence, "wrong")
      {:incorrect, ["psa"]}
  """
  def check_answer(%Sentence{} = sentence, user_input) do
    expected_forms = get_expected_forms(sentence)
    normalized_input = normalize(user_input)

    match =
      Enum.find(expected_forms, fn form ->
        normalize(form) == normalized_input
      end)

    case match do
      nil -> {:incorrect, expected_forms}
      form -> {:correct, form}
    end
  end

  @doc """
  Gets all display forms that match the sentence's blank_form_tag.

  Returns a list of display_form strings from search_terms.

  ## Examples

      iex> Exercises.get_expected_forms(sentence)
      ["psa"]
  """
  def get_expected_forms(%Sentence{word_id: word_id, blank_form_tag: form_tag}) do
    SearchTerm
    |> where([st], st.word_id == ^word_id and st.form_tag == ^String.downcase(form_tag))
    |> select([st], st.display_form)
    |> Repo.all()
  end

  @doc """
  Returns a sorted list of parts of speech that have at least one sentence.

  ## Examples

      iex> Exercises.list_available_parts_of_speech()
      [:noun, :verb]
  """
  def list_available_parts_of_speech do
    Sentence
    |> join(:inner, [s], w in assoc(s, :word))
    |> select([s, w], w.part_of_speech)
    |> distinct(true)
    |> Repo.all()
    |> Enum.sort()
  end

  # Private functions

  defp normalize(text) do
    text
    |> String.trim()
    |> Transliteration.to_latin()
    |> Transliteration.strip_diacritics()
    |> String.downcase()
  end

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:word_id, word_id}, query ->
        where(query, [s], s.word_id == ^word_id)

      {:part_of_speech, pos}, query ->
        query
        |> join(:inner, [s], w in assoc(s, :word), as: :word)
        |> where([s, word: w], w.part_of_speech == ^pos)

      _, query ->
        query
    end)
  end

  defp maybe_preload_word(nil), do: nil
  defp maybe_preload_word(sentence), do: Repo.preload(sentence, :word)
end
