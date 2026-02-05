defmodule Ohmyword.Vocabulary.Word do
  @moduledoc """
  Schema for vocabulary words - the source of truth for the dictionary.

  Stores root forms (nominative singular for nouns, infinitive for verbs)
  with full linguistic metadata. This is the "dictionary definition" and
  the fuel for the future rule engine.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @parts_of_speech ~w(noun verb adjective adverb pronoun preposition conjunction interjection particle numeral)a
  @genders ~w(masculine feminine neuter)a
  @aspects ~w(perfective imperfective biaspectual)a

  # Parts of speech that require gender
  @gendered_pos ~w(noun adjective pronoun)a

  schema "vocabulary_words" do
    # Identity
    field :term, :string
    field :translation, :string
    field :translations, {:array, :string}, default: []
    field :part_of_speech, Ecto.Enum, values: @parts_of_speech
    field :proficiency_level, :integer, default: 1

    # Noun-specific
    field :gender, Ecto.Enum, values: @genders
    field :animate, :boolean
    field :declension_class, :string

    # Verb-specific
    field :verb_aspect, Ecto.Enum, values: @aspects
    field :conjugation_class, :string
    field :reflexive, :boolean, default: false
    field :transitive, :boolean

    # Relationships
    belongs_to :aspect_pair, __MODULE__
    has_many :search_terms, Ohmyword.Search.SearchTerm

    # Flexible metadata
    field :grammar_metadata, :map, default: %{}

    # Content
    field :example_sentence_rs, :string
    field :example_sentence_en, :string
    field :audio_url, :string
    field :image_url, :string
    field :usage_notes, :string

    # Categorization
    field :categories, {:array, :string}, default: []

    timestamps(type: :utc_datetime)
  end

  @required_fields ~w(term translation part_of_speech)a
  @optional_fields ~w(
    translations proficiency_level gender animate declension_class
    verb_aspect conjugation_class reflexive transitive aspect_pair_id
    grammar_metadata example_sentence_rs example_sentence_en
    audio_url image_url usage_notes categories
  )a

  def changeset(word, attrs) do
    word
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:proficiency_level, greater_than: 0, less_than: 10)
    |> validate_gender_required()
    |> validate_animate_for_masculine_nouns()
    |> validate_verb_aspect_required()
    |> foreign_key_constraint(:aspect_pair_id)
  end

  # Gender is required for nouns, adjectives, and pronouns
  defp validate_gender_required(changeset) do
    pos = get_field(changeset, :part_of_speech)

    if pos in @gendered_pos do
      validate_required(changeset, [:gender])
    else
      changeset
    end
  end

  # Animate is required for masculine nouns (must be explicitly true or false)
  defp validate_animate_for_masculine_nouns(changeset) do
    pos = get_field(changeset, :part_of_speech)
    gender = get_field(changeset, :gender)

    if pos == :noun and gender == :masculine do
      validate_required(changeset, [:animate])
    else
      changeset
    end
  end

  # Verb aspect is required for verbs
  defp validate_verb_aspect_required(changeset) do
    pos = get_field(changeset, :part_of_speech)

    if pos == :verb do
      validate_required(changeset, [:verb_aspect])
    else
      changeset
    end
  end
end
