defmodule Ohmyword.Vocabulary do
  @moduledoc """
  The Vocabulary context.

  Provides the public API for vocabulary operations including
  listing, fetching, creating, updating, and deleting words.
  """

  import Ecto.Query

  alias Ohmyword.Repo
  alias Ohmyword.Vocabulary.Word
  alias Ohmyword.Linguistics.CacheManager

  @doc """
  Lists words with optional filters.

  ## Options

    * `:part_of_speech` - Filter by part of speech (atom)
    * `:proficiency_level` - Filter by proficiency level (integer)

  ## Examples

      iex> Vocabulary.list_words()
      [%Word{}, ...]

      iex> Vocabulary.list_words(part_of_speech: :noun)
      [%Word{part_of_speech: :noun}, ...]

      iex> Vocabulary.list_words(proficiency_level: 1)
      [%Word{proficiency_level: 1}, ...]
  """
  def list_words(opts \\ []) do
    Word
    |> apply_filters(opts)
    |> Repo.all()
  end

  @doc """
  Gets a word by ID.

  Raises `Ecto.NoResultsError` if the word does not exist.

  ## Examples

      iex> Vocabulary.get_word!(123)
      %Word{}

      iex> Vocabulary.get_word!(0)
      ** (Ecto.NoResultsError)
  """
  def get_word!(id) do
    Repo.get!(Word, id)
  end

  @doc """
  Gets a random word, optionally filtered by criteria.

  Returns `nil` if no words match the criteria.

  ## Options

    * `:proficiency_level` - Filter by proficiency level (integer)

  ## Examples

      iex> Vocabulary.get_random_word()
      %Word{}

      iex> Vocabulary.get_random_word(proficiency_level: 1)
      %Word{proficiency_level: 1}
  """
  def get_random_word(opts \\ []) do
    Word
    |> apply_filters(opts)
    |> order_by(fragment("RANDOM()"))
    |> limit(1)
    |> Repo.one()
  end

  @doc """
  Creates a word.

  ## Examples

      iex> Vocabulary.create_word(%{term: "pas", translation: "dog", ...})
      {:ok, %Word{}}

      iex> Vocabulary.create_word(%{invalid: "attrs"})
      {:error, %Ecto.Changeset{}}
  """
  def create_word(attrs) do
    %Word{}
    |> Word.changeset(attrs)
    |> Repo.insert()
    |> maybe_regenerate_search_terms()
  end

  @doc """
  Updates a word.

  ## Examples

      iex> Vocabulary.update_word(word, %{translation: "new translation"})
      {:ok, %Word{}}

      iex> Vocabulary.update_word(word, %{term: nil})
      {:error, %Ecto.Changeset{}}
  """
  def update_word(%Word{} = word, attrs) do
    word
    |> Word.changeset(attrs)
    |> Repo.update()
    |> maybe_regenerate_search_terms()
  end

  @doc """
  Deletes a word.

  Associated search terms are deleted via database cascade.

  ## Examples

      iex> Vocabulary.delete_word(word)
      {:ok, %Word{}}
  """
  def delete_word(%Word{} = word) do
    Repo.delete(word)
  end

  @doc """
  Returns a sorted list of parts of speech that have at least one word.

  ## Examples

      iex> Vocabulary.list_available_parts_of_speech()
      [:adjective, :noun, :verb]
  """
  def list_available_parts_of_speech do
    Word
    |> select([w], w.part_of_speech)
    |> distinct(true)
    |> Repo.all()
    |> Enum.sort()
  end

  # Private functions

  defp maybe_regenerate_search_terms({:ok, word}) do
    CacheManager.regenerate_word(word)
    {:ok, word}
  end

  defp maybe_regenerate_search_terms({:error, _changeset} = error), do: error

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:part_of_speech, pos}, query ->
        where(query, [w], w.part_of_speech == ^pos)

      {:proficiency_level, level}, query ->
        where(query, [w], w.proficiency_level == ^level)

      _, query ->
        query
    end)
  end
end
