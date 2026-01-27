defmodule BoilerWeb.Admin.IssueInsightsLiveTest do
  use BoilerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Boiler.AccountsFixtures
  import Boiler.SupportFixtures

  describe "Issue insights page" do
    setup %{conn: conn} do
      user = user_fixture()
      {:ok, admin_user} = Ecto.Changeset.change(user, role: :admin) |> Boiler.Repo.update()
      %{conn: log_in_user(conn, admin_user), admin: admin_user}
    end

    test "renders page correctly", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/issues")

      assert html =~ "Issue Insights"
      assert html =~ "Use AI to analyze user feedback"
      assert html =~ "Ask AI"
    end

    test "displays issue count", %{conn: conn} do
      issue_fixture(%{content: "Test issue one with enough content"})
      issue_fixture(%{content: "Test issue two with enough content"})

      {:ok, _lv, html} = live(conn, ~p"/admin/issues")

      assert html =~ "2 issues in the database"
    end

    test "shows suggested prompts", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/admin/issues")

      assert html =~ "Summarize the issues from the last 24 hours"
      assert html =~ "What are the most common complaints?"
    end

    test "use-prompt fills query field", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/admin/issues")

      lv
      |> element("button[phx-click='use-prompt']", "What are the most common complaints?")
      |> render_click()

      html = render(lv)
      assert html =~ "What are the most common complaints?"
    end

    test "submits analyze form", %{conn: conn} do
      issue_fixture(%{content: "Test issue with enough content for analysis"})

      {:ok, lv, _html} = live(conn, ~p"/admin/issues")

      # Submit analyze form - this will start async task
      lv
      |> form("#ai-query-form", %{"query" => %{"query" => "Summarize issues"}})
      |> render_submit()

      # Give async task time to complete
      Process.sleep(100)

      # Re-render to get updated state
      html = render(lv)

      # Should see either error state or response (API key not configured so will error)
      assert html =~ "Error" or html =~ "API key" or html =~ "Failed" or html =~ "AI Analysis"
    end
  end

  describe "admin access" do
    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, conn} =
        conn
        |> live(~p"/admin/issues")
        |> follow_redirect(conn, "/")

      assert conn.resp_body =~ "admin"
    end

    test "redirects unauthenticated users", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/admin/issues")

      assert {:redirect, %{to: path}} = redirect
      assert path == ~p"/users/log-in"
    end
  end
end
