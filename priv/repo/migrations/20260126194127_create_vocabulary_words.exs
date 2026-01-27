defmodule Ohmyword.Repo.Migrations.CreateVocabularyWords do
  use Ecto.Migration

  def change do
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
  end
end
