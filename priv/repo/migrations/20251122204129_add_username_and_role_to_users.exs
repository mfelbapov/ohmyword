defmodule Ohmyword.Repo.Migrations.AddUsernameAndRoleToUsers do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :username, :citext
      add :role, :string, null: false, default: "member"
    end

    # Populate username for existing users
    execute "UPDATE users SET username = 'user' || id"

    # Now make it not null
    alter table(:users) do
      modify :username, :citext, null: false
    end

    create unique_index(:users, [:username])
  end

  def down do
    drop unique_index(:users, [:username])

    alter table(:users) do
      remove :role
      remove :username
    end
  end
end
