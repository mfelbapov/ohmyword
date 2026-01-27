defmodule Boiler.Support do
  @moduledoc """
  The Support context for managing user-submitted issues and feedback.
  """

  import Ecto.Query, warn: false
  alias Boiler.Repo
  alias Boiler.Support.Issue

  @doc """
  Returns a list of issues with Flop pagination/filtering support.

  ## Examples

      iex> list_issues(flop)
      {:ok, {[%Issue{}], %Flop.Meta{}}}

  """
  def list_issues(flop \\ %Flop{}) do
    Flop.validate_and_run(Issue, flop, for: Issue)
  end

  @doc """
  Returns the most recent N issues for AI context.

  ## Examples

      iex> list_recent_issues(50)
      [%Issue{}, ...]

  """
  def list_recent_issues(limit \\ 50) do
    from(i in Issue,
      order_by: [desc: i.inserted_at, desc: i.id],
      limit: ^limit,
      preload: [:user]
    )
    |> Repo.all()
  end

  @doc """
  Gets a single issue by ID.

  Raises `Ecto.NoResultsError` if the Issue does not exist.

  ## Examples

      iex> get_issue!(123)
      %Issue{}

      iex> get_issue!(456)
      ** (Ecto.NoResultsError)

  """
  def get_issue!(id) do
    Repo.get!(Issue, id)
  end

  @doc """
  Creates an issue for the given user.

  ## Examples

      iex> create_issue(current_scope, %{field: value})
      {:ok, %Issue{}}

      iex> create_issue(current_scope, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_issue(current_scope, attrs \\ %{}) do
    %Issue{}
    |> Issue.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, current_scope.user)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking issue changes.

  ## Examples

      iex> change_issue(issue)
      %Ecto.Changeset{data: %Issue{}}

  """
  def change_issue(%Issue{} = issue, attrs \\ %{}) do
    Issue.changeset(issue, attrs)
  end
end
