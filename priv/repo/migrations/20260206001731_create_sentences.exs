defmodule Ohmyword.Repo.Migrations.CreateSentences do
  use Ecto.Migration

  def change do
    create table(:sentences) do
      add :text, :string, null: false
      add :translation, :string, null: false
      add :blank_form_tag, :string, null: false
      add :hint, :string
      add :word_id, references(:vocabulary_words, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:sentences, [:word_id])
  end
end
