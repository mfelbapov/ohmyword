defmodule Ohmyword.Repo.Migrations.RedesignSentences do
  use Ecto.Migration

  def up do
    # Delete all existing sentence rows (they'll be re-seeded)
    execute "DELETE FROM sentences"

    # Drop old columns from sentences
    alter table(:sentences) do
      remove :blank_form_tag
      remove :hint
      remove :word_id
    end

    # Rename text -> text_rs, translation -> text_en
    rename table(:sentences), :text, to: :text_rs
    rename table(:sentences), :translation, to: :text_en

    # Create sentence_words join table
    create table(:sentence_words) do
      add :position, :integer, null: false
      add :form_tag, :string, null: false
      add :sentence_id, references(:sentences, on_delete: :delete_all), null: false
      add :word_id, references(:vocabulary_words, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:sentence_words, [:sentence_id, :position])
    create index(:sentence_words, [:word_id])

    # Drop example_sentence fields from vocabulary_words
    alter table(:vocabulary_words) do
      remove :example_sentence_rs
      remove :example_sentence_en
    end
  end

  def down do
    # Restore example_sentence fields on vocabulary_words
    alter table(:vocabulary_words) do
      add :example_sentence_rs, :string
      add :example_sentence_en, :string
    end

    # Drop sentence_words table
    drop table(:sentence_words)

    # Rename back
    rename table(:sentences), :text_rs, to: :text
    rename table(:sentences), :text_en, to: :translation

    # Restore old columns on sentences
    alter table(:sentences) do
      add :blank_form_tag, :string
      add :hint, :string
      add :word_id, references(:vocabulary_words, on_delete: :delete_all)
    end
  end
end
