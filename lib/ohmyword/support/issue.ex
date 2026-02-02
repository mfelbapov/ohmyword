defmodule Ohmyword.Support.Issue do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Flop.Schema,
           filterable: [:status, :user_id], sortable: [:inserted_at, :status], default_limit: 20}

  schema "issues" do
    field :content, :string
    field :status, :string, default: "new"

    belongs_to :user, Ohmyword.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
  A changeset for creating and updating issues.
  """
  def changeset(issue, attrs) do
    issue
    |> cast(attrs, [:content, :status])
    |> validate_required([:content])
    |> validate_length(:content, min: 10, max: 5000)
    |> validate_inclusion(:status, ["new", "reviewed", "archived"])
  end
end
