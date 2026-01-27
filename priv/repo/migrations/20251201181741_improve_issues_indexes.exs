defmodule Boiler.Repo.Migrations.ImproveIssuesIndexes do
  use Ecto.Migration

  def change do
    # Drop the old single-column index on inserted_at
    drop_if_exists index(:issues, [:inserted_at])

    # Create a composite index on inserted_at and id for better query performance
    # This supports ORDER BY inserted_at DESC, id DESC efficiently
    create index(:issues, [:inserted_at, :id])
  end
end
