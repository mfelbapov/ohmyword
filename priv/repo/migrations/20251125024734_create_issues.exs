defmodule Ohmyword.Repo.Migrations.CreateIssues do
  use Ecto.Migration

  def change do
    create table(:issues) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :content, :text, null: false
      add :status, :string, default: "new", null: false

      timestamps(type: :utc_datetime)
    end

    create index(:issues, [:user_id])
    create index(:issues, [:status])
    create index(:issues, [:inserted_at])
  end
end
