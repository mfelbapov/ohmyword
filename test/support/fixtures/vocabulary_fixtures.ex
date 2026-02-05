defmodule Ohmyword.VocabularyFixtures do
  @moduledoc """
  Test fixtures for vocabulary-related schemas.
  """

  alias Ohmyword.Repo
  alias Ohmyword.Vocabulary.Word
  alias Ohmyword.Search.SearchTerm

  @doc """
  Creates a word with the given attributes merged with defaults.
  """
  def word_fixture(attrs \\ %{}) do
    {:ok, word} =
      %Word{}
      |> Word.changeset(
        Enum.into(attrs, %{
          term: "test#{System.unique_integer([:positive])}",
          translation: "test translation",
          part_of_speech: :adverb,
          proficiency_level: 1
        })
      )
      |> Repo.insert()

    word
  end

  @doc """
  Creates a noun with the given attributes.
  Defaults to masculine animate noun.
  """
  def noun_fixture(attrs \\ %{}) do
    word_fixture(
      Map.merge(
        %{
          term: "pas#{System.unique_integer([:positive])}",
          translation: "dog",
          part_of_speech: :noun,
          gender: :masculine,
          animate: true,
          declension_class: "consonant"
        },
        attrs
      )
    )
  end

  @doc """
  Creates a feminine noun with the given attributes.
  """
  def feminine_noun_fixture(attrs \\ %{}) do
    word_fixture(
      Map.merge(
        %{
          term: "zena#{System.unique_integer([:positive])}",
          translation: "woman",
          part_of_speech: :noun,
          gender: :feminine,
          declension_class: "a-stem"
        },
        attrs
      )
    )
  end

  @doc """
  Creates a neuter noun with the given attributes.
  """
  def neuter_noun_fixture(attrs \\ %{}) do
    word_fixture(
      Map.merge(
        %{
          term: "selo#{System.unique_integer([:positive])}",
          translation: "village",
          part_of_speech: :noun,
          gender: :neuter,
          declension_class: "o-stem"
        },
        attrs
      )
    )
  end

  @doc """
  Creates a verb with the given attributes.
  """
  def verb_fixture(attrs \\ %{}) do
    word_fixture(
      Map.merge(
        %{
          term: "pisati#{System.unique_integer([:positive])}",
          translation: "to write",
          part_of_speech: :verb,
          verb_aspect: :imperfective,
          conjugation_class: "e-verb"
        },
        attrs
      )
    )
  end

  @doc """
  Creates an adjective with the given attributes.
  """
  def adjective_fixture(attrs \\ %{}) do
    word_fixture(
      Map.merge(
        %{
          term: "dobar#{System.unique_integer([:positive])}",
          translation: "good",
          part_of_speech: :adjective,
          gender: :masculine
        },
        attrs
      )
    )
  end

  @doc """
  Creates a search term with the given attributes.
  """
  def search_term_fixture(attrs \\ %{}) do
    word = attrs[:word] || word_fixture()
    default_term = "form#{System.unique_integer([:positive])}"

    {:ok, search_term} =
      %SearchTerm{}
      |> SearchTerm.changeset(
        Enum.into(attrs, %{
          term: default_term,
          display_form: default_term,
          form_tag: "nom_sg",
          word_id: word.id
        })
      )
      |> Repo.insert()

    search_term
  end
end
