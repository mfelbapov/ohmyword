defmodule Ohmyword.ExercisesFixtures do
  @moduledoc """
  Test fixtures for exercises-related schemas.
  """

  alias Ohmyword.Repo
  alias Ohmyword.Exercises.Sentence

  import Ohmyword.VocabularyFixtures

  @doc """
  Creates a sentence with the given attributes merged with defaults.
  """
  def sentence_fixture(attrs \\ %{}) do
    word = attrs[:word] || noun_fixture()

    {:ok, sentence} =
      %Sentence{}
      |> Sentence.changeset(
        Enum.into(attrs, %{
          text: "Vidim {blank}.",
          translation: "I see the thing.",
          blank_form_tag: "acc_sg",
          word_id: word.id
        })
      )
      |> Repo.insert()

    Repo.preload(sentence, :word)
  end
end
