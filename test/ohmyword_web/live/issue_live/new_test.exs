defmodule OhmywordWeb.IssueLive.NewTest do
  use OhmywordWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Ohmyword.AccountsFixtures

  describe "New issue page" do
    setup %{conn: conn} do
      user = user_fixture()
      %{conn: log_in_user(conn, user), user: user}
    end

    test "renders form correctly", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/issues/new")

      assert html =~ "Submit Feedback or Report an Issue"
      assert html =~ "Description"
      assert html =~ "Submit Feedback"
    end

    test "validates required fields on change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/issues/new")

      result =
        lv
        |> form("#issue-form", %{"issue" => %{"content" => "short"}})
        |> render_change()

      assert result =~ "should be at least 10 character(s)"
    end

    test "creates issue on valid submission", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/issues/new")

      result =
        lv
        |> form("#issue-form", %{
          "issue" => %{"content" => "This is a detailed issue report with enough content"}
        })
        |> render_submit()

      assert result =~ "Thank you for your feedback!"
    end

    test "shows errors on invalid submission", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/issues/new")

      result =
        lv
        |> form("#issue-form", %{"issue" => %{"content" => "short"}})
        |> render_submit()

      assert result =~ "should be at least 10 character(s)"
    end

    test "clears form after successful submission", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/issues/new")

      lv
      |> form("#issue-form", %{
        "issue" => %{"content" => "This is a detailed issue report with enough content"}
      })
      |> render_submit()

      # Form should be cleared (textarea should be empty)
      html = render(lv)
      refute html =~ "This is a detailed issue report"
    end
  end

  describe "authentication" do
    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/issues/new")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end
end
