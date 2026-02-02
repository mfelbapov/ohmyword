defmodule Ohmyword.SupportTest do
  use Ohmyword.DataCase

  alias Ohmyword.Support

  import Ohmyword.SupportFixtures
  import Ohmyword.AccountsFixtures

  describe "list_recent_issues/1" do
    test "returns recent issues ordered by inserted_at desc" do
      issue1 = issue_fixture(%{content: "First issue"})
      issue2 = issue_fixture(%{content: "Second issue"})

      issues = Support.list_recent_issues(10)

      assert length(issues) == 2
      assert Enum.at(issues, 0).id == issue2.id
      assert Enum.at(issues, 1).id == issue1.id
    end

    test "limits results to specified number" do
      for i <- 1..10 do
        issue_fixture(%{content: "This is test issue number #{i} with sufficient content length"})
      end

      issues = Support.list_recent_issues(5)
      assert length(issues) == 5
    end
  end

  describe "get_issue!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Support.get_issue!(-1)
      end
    end

    test "returns the issue with the given id" do
      issue = issue_fixture()
      assert Support.get_issue!(issue.id).id == issue.id
    end
  end

  describe "create_issue/2" do
    test "creates issue with valid data" do
      user_scope = user_scope_fixture()
      attrs = valid_issue_attributes()

      assert {:ok, issue} = Support.create_issue(user_scope, attrs)
      assert issue.content == attrs.content
      assert issue.status == "new"
      assert issue.user_id == user_scope.user.id
    end

    test "requires content" do
      user_scope = user_scope_fixture()

      assert {:error, changeset} = Support.create_issue(user_scope, %{})
      assert %{content: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates minimum content length" do
      user_scope = user_scope_fixture()

      assert {:error, changeset} = Support.create_issue(user_scope, %{content: "short"})
      assert "should be at least 10 character(s)" in errors_on(changeset).content
    end
  end

  describe "change_issue/2" do
    test "returns a changeset" do
      issue = issue_fixture()
      assert %Ecto.Changeset{} = Support.change_issue(issue)
    end
  end
end
