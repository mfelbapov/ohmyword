defmodule Ohmyword.ExercisesFixtures do
  @moduledoc """
  Test fixtures for exercises-related schemas.
  """

  alias Ohmyword.Repo
  alias Ohmyword.Exercises.Sentence
  alias Ohmyword.Exercises.SentenceWord

  import Ohmyword.VocabularyFixtures

  @doc """
  Creates a sentence with the given attributes merged with defaults.

  Returns a sentence with preloaded sentence_words (empty unless word annotations are added).
  """
  def sentence_fixture(attrs \\ %{}) do
    {:ok, sentence} =
      %Sentence{}
      |> Sentence.changeset(
        Enum.into(attrs, %{
          text_rs: "Vidim velikog psa.",
          text_en: "I see a big dog."
        })
      )
      |> Repo.insert()

    Repo.preload(sentence, sentence_words: :word)
  end

  @doc """
  Creates a sentence_word linking a word to a position in a sentence.
  """
  def sentence_word_fixture(attrs \\ %{}) do
    sentence = attrs[:sentence] || sentence_fixture()
    word = attrs[:word] || noun_fixture()

    {:ok, sentence_word} =
      %SentenceWord{}
      |> SentenceWord.changeset(
        Enum.into(attrs, %{
          position: 0,
          form_tag: "acc_sg",
          sentence_id: sentence.id,
          word_id: word.id
        })
      )
      |> Repo.insert()

    Repo.preload(sentence_word, :word)
  end

  @doc """
  Creates a sentence with annotated words ready for exercises.

  Returns sentence with preloaded sentence_words.
  """
  def sentence_with_words_fixture(attrs \\ %{}) do
    word = attrs[:word] || noun_fixture(%{term: "pas"})

    sentence =
      sentence_fixture(%{
        text_rs: Map.get(attrs, :text_rs, "Vidim psa."),
        text_en: Map.get(attrs, :text_en, "I see a dog.")
      })

    form_tag = Map.get(attrs, :form_tag, "acc_sg")
    position = Map.get(attrs, :position, 1)

    sentence_word_fixture(%{
      sentence: sentence,
      word: word,
      position: position,
      form_tag: form_tag
    })

    Repo.preload(sentence, [sentence_words: :word], force: true)
  end
end
