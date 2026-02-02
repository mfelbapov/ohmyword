defmodule Ohmyword.SupportFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Ohmyword.Support` context.
  """

  alias Ohmyword.Support

  def valid_issue_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      content:
        "This is a test issue with enough content to pass validation minimum length requirements."
    })
  end

  def issue_fixture(attrs \\ %{}) do
    user_scope = Ohmyword.AccountsFixtures.user_scope_fixture()

    {:ok, issue} =
      attrs
      |> valid_issue_attributes()
      |> (&Support.create_issue(user_scope, &1)).()

    issue
  end
end
