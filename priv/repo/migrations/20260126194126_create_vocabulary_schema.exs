defmodule Ohmyword.Repo.Migrations.CreateVocabularySchema do
  use Ecto.Migration

  def up do
    # Create enums
    execute """
    CREATE TYPE part_of_speech AS ENUM (
      'noun', 'verb', 'adjective', 'adverb', 'pronoun',
      'preposition', 'conjunction', 'interjection', 'particle', 'numeral'
    )
    """

    execute """
    CREATE TYPE grammatical_gender AS ENUM ('masculine', 'feminine', 'neuter')
    """

    execute """
    CREATE TYPE verb_aspect AS ENUM ('perfective', 'imperfective', 'biaspectual')
    """

    execute """
    CREATE TYPE search_term_source AS ENUM ('seed', 'manual', 'engine')
    """

    # Create vocabulary_words table
    create table(:vocabulary_words) do
      # Identity fields
      add :term, :string, null: false
      add :translation, :string, null: false
      add :translations, {:array, :string}, default: []
      add :part_of_speech, :part_of_speech, null: false
      add :proficiency_level, :integer, null: false, default: 1

      # Noun-specific fields
      add :gender, :grammatical_gender
      add :animate, :boolean
      add :declension_class, :string

      # Verb-specific fields
      add :verb_aspect, :verb_aspect
      add :conjugation_class, :string
      add :reflexive, :boolean, default: false
      add :transitive, :boolean

      # Self-reference for aspect pairs
      add :aspect_pair_id, references(:vocabulary_words, on_delete: :nilify_all)

      # Flexible metadata
      add :grammar_metadata, :map, default: %{}

      # Content & media fields
      add :example_sentence_rs, :text
      add :example_sentence_en, :text
      add :audio_url, :string
      add :image_url, :string
      add :usage_notes, :text

      # Categorization
      add :categories, {:array, :string}, default: []

      timestamps(type: :utc_datetime)
    end

    create index(:vocabulary_words, [:term])
    create index(:vocabulary_words, [:part_of_speech])
    create index(:vocabulary_words, [:proficiency_level])
    create index(:vocabulary_words, [:categories], using: :gin)

    # Create search_terms table
    create table(:search_terms) do
      add :term, :string, null: false
      add :form_tag, :string, null: false
      add :word_id, references(:vocabulary_words, on_delete: :delete_all), null: false
      add :source, :search_term_source, null: false, default: "seed"
      add :locked, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:search_terms, [:term])
    create unique_index(:search_terms, [:term, :word_id, :form_tag])
  end

  def down do
    drop table(:search_terms)
    drop table(:vocabulary_words)

    execute "DROP TYPE IF EXISTS search_term_source"
    execute "DROP TYPE IF EXISTS verb_aspect"
    execute "DROP TYPE IF EXISTS grammatical_gender"
    execute "DROP TYPE IF EXISTS part_of_speech"
  end
end
