defmodule Ohmyword.Repo.Migrations.CreateSearchTerms do
  use Ecto.Migration

  def change do
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
end
