defmodule Ohmyword.Exercises do
  @moduledoc """
  The Exercises context.

  Provides the public API for exercise operations including
  fetching sentences, selecting blanks by difficulty, and checking answers.
  """

  import Ecto.Query

  alias Ohmyword.Repo
  alias Ohmyword.Exercises.Sentence
  alias Ohmyword.Exercises.SentenceWord
  alias Ohmyword.Search.SearchTerm
  alias Ohmyword.Utils.Transliteration

  @doc """
  Tokenizes a Serbian sentence into word tokens.

  Returns a list of word strings extracted from the text.
  Must be consistent between seed import and UI rendering.
  """
  def tokenize(text) do
    Regex.scan(~r/[\p{L}]+/u, text)
    |> List.flatten()
  end

  @doc """
  Gets a sentence by ID with preloaded sentence_words and their words.

  Raises `Ecto.NoResultsError` if the sentence does not exist.
  """
  def get_sentence!(id) do
    Sentence
    |> Repo.get!(id)
    |> Repo.preload(sentence_words: :word)
  end

  @doc """
  Gets a random sentence, optionally filtered by part of speech.

  Returns `nil` if no sentences match the criteria.

  ## Options

    * `:part_of_speech` - Filter by the word's part of speech
  """
  def get_random_sentence(opts \\ []) do
    Sentence
    |> apply_filters(opts)
    |> order_by(fragment("RANDOM()"))
    |> limit(1)
    |> Repo.one()
    |> maybe_preload()
  end

  @doc """
  Creates a sentence.
  """
  def create_sentence(attrs) do
    %Sentence{}
    |> Sentence.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets sentences containing a given word.

  ## Options

    * `:limit` - Maximum number of sentences to return (default: 3)
  """
  def get_sentences_for_word(word_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 3)

    Sentence
    |> join(:inner, [s], sw in SentenceWord, on: sw.sentence_id == s.id)
    |> where([s, sw], sw.word_id == ^word_id)
    |> distinct([s, sw], s.id)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload(sentence_words: :word)
  end

  @doc """
  Batch query: returns a map of word_id => [sentence] for a list of word IDs.
  Avoids N+1 queries in dictionary search results.
  """
  def get_sentence_map_for_words(word_ids) when is_list(word_ids) do
    if word_ids == [] do
      %{}
    else
      word_sentence_pairs =
        SentenceWord
        |> where([sw], sw.word_id in ^word_ids)
        |> select([sw], {sw.word_id, sw.sentence_id})
        |> distinct(true)
        |> Repo.all()

      # Group by word_id and take first sentence per word
      sentence_ids_by_word =
        word_sentence_pairs
        |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
        |> Map.new(fn {word_id, sids} -> {word_id, Enum.take(sids, 1)} end)

      # Load all needed sentences in one query
      all_sentence_ids = sentence_ids_by_word |> Map.values() |> List.flatten() |> Enum.uniq()

      sentences_by_id =
        Sentence
        |> where([s], s.id in ^all_sentence_ids)
        |> Repo.all()
        |> Map.new(fn s -> {s.id, s} end)

      Map.new(sentence_ids_by_word, fn {word_id, sids} ->
        {word_id, Enum.map(sids, &Map.get(sentences_by_id, &1)) |> Enum.reject(&is_nil/1)}
      end)
    end
  end

  @doc """
  Selects which sentence_words to blank based on difficulty.

  Difficulty levels:
    * `1` - One random blank
    * `2` - Approximately half the annotated words
    * `3` - All annotated words
  """
  def select_blanks(%Sentence{sentence_words: sentence_words}, difficulty) do
    case difficulty do
      1 ->
        if sentence_words == [] do
          []
        else
          [Enum.random(sentence_words)]
        end

      2 ->
        count = max(1, div(length(sentence_words), 2))

        sentence_words
        |> Enum.shuffle()
        |> Enum.take(count)

      3 ->
        sentence_words

      _ ->
        sentence_words
    end
  end

  @doc """
  Checks a single answer for a sentence_word.

  Returns `{:correct, matched_form}`, `{:incorrect, expected_forms}`,
  or `{:error, :no_forms}`.
  """
  def check_answer(%SentenceWord{} = sentence_word, user_input) do
    expected_forms = get_expected_forms(sentence_word)

    if expected_forms == [] do
      {:error, :no_forms}
    else
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
  end

  @doc """
  Checks all answers for a sentence at once.

  Takes a sentence (with preloaded sentence_words) and a map of
  `%{position => user_input}`. Returns a map of `%{position => result}`.
  """
  def check_all_answers(%Sentence{sentence_words: sentence_words}, answers) do
    Map.new(answers, fn {position, input} ->
      pos = if is_binary(position), do: String.to_integer(position), else: position

      sw = Enum.find(sentence_words, &(&1.position == pos))

      result =
        if sw do
          check_answer(sw, input)
        else
          {:error, :no_forms}
        end

      {pos, result}
    end)
  end

  @doc """
  Gets all display forms that match a sentence_word's word_id and form_tag.
  """
  def get_expected_forms(%SentenceWord{word_id: word_id, form_tag: form_tag}) do
    SearchTerm
    |> where([st], st.word_id == ^word_id and st.form_tag == ^String.downcase(form_tag))
    |> select([st], st.display_form)
    |> Repo.all()
  end

  @doc """
  Returns a sorted list of parts of speech that have at least one sentence.
  """
  def list_available_parts_of_speech do
    Sentence
    |> join(:inner, [s], sw in SentenceWord, on: sw.sentence_id == s.id)
    |> join(:inner, [s, sw], w in assoc(sw, :word))
    |> select([s, sw, w], w.part_of_speech)
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
      {:part_of_speech, pos}, query ->
        query
        |> join(:inner, [s], sw in SentenceWord, on: sw.sentence_id == s.id, as: :sentence_word)
        |> join(:inner, [s, sentence_word: sw], w in assoc(sw, :word), as: :word)
        |> where([s, sentence_word: sw, word: w], w.part_of_speech == ^pos)
        |> distinct([s], s.id)

      _, query ->
        query
    end)
  end

  defp maybe_preload(nil), do: nil
  defp maybe_preload(sentence), do: Repo.preload(sentence, sentence_words: :word)
end
