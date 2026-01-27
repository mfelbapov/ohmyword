defmodule Boiler.Repo.Migrations.AddIssueStatusConstraint do
  use Ecto.Migration

  def change do
    # Add check constraint to ensure status is one of the valid values
    create constraint(:issues, :status_must_be_valid,
             check: "status IN ('new', 'reviewed', 'archived')"
           )
  end
end
