defmodule BoilerWeb.UserLive.ResendConfirmationTest do
  use BoilerWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Boiler.AccountsFixtures

  setup do
    %{unconfirmed_user: unconfirmed_user_fixture(), confirmed_user: user_fixture()}
  end

  describe "Resend confirmation" do
    test "renders resend confirmation page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/resend-confirmation")
      assert html =~ "Resend confirmation instructions"
      assert html =~ "Enter your email address and we&#39;ll send you a new confirmation link"
    end

    test "sends confirmation instructions for unconfirmed user", %{
      conn: conn,
      unconfirmed_user: user
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/resend-confirmation")

      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: user.email})
        |> render_submit()

      assert {:error, {:live_redirect, %{to: "/users/log-in"}}} = result
    end

    test "shows message for already confirmed user", %{conn: conn, confirmed_user: user} do
      {:ok, lv, _html} = live(conn, ~p"/users/resend-confirmation")

      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: user.email})
        |> render_submit()

      assert {:error, {:live_redirect, %{to: "/users/log-in"}}} = result
    end

    test "shows generic message for non-existent email", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/resend-confirmation")

      result =
        lv
        |> form("#resend_confirmation_form", user: %{email: "unknown@example.com"})
        |> render_submit()

      # Should show the same message to prevent user enumeration
      assert {:error, {:live_redirect, %{to: "/users/log-in"}}} = result
    end

    test "pre-fills email when redirected from login with unconfirmed user", %{
      conn: conn,
      unconfirmed_user: user
    } do
      # Try to log in with unconfirmed user - should redirect to resend page with email in flash
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email, "password" => valid_user_password()}
        })

      assert redirected_to(conn) == ~p"/users/resend-confirmation"

      # Follow redirect and check that email is pre-filled
      {:ok, _lv, html} = live(conn, ~p"/users/resend-confirmation")

      assert html =~ user.email
    end
  end
end
