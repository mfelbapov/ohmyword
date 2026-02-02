defmodule OhmywordWeb.UserLive.ConfirmationTest do
  use OhmywordWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Ohmyword.AccountsFixtures

  alias Ohmyword.Accounts

  setup do
    %{unconfirmed_user: unconfirmed_user_fixture(), confirmed_user: user_fixture()}
  end

  describe "Confirm user" do
    test "renders confirmation page", %{conn: conn, unconfirmed_user: user} do
      {encoded_token, _hashed_token} = generate_user_confirmation_token(user)

      {:ok, _lv, html} = live(conn, ~p"/users/confirm/#{encoded_token}")
      assert html =~ "Email confirmed!"
      assert html =~ "Continue to Log in"
      assert Accounts.get_user!(user.id).confirmed_at
    end

    test "confirms the given token once", %{conn: conn, unconfirmed_user: user} do
      {encoded_token, _hashed_token} = generate_user_confirmation_token(user)

      {:ok, _lv, _html} = live(conn, ~p"/users/confirm/#{encoded_token}")

      assert Accounts.get_user!(user.id).confirmed_at

      # Using the token again should still work (user is already confirmed)
      # This allows the confirmation page to be refreshed without errors
      {:ok, _lv, html} = live(conn, ~p"/users/confirm/#{encoded_token}")

      assert html =~ "Email confirmed!"
    end

    test "does not confirm already confirmed user", %{
      conn: _conn,
      confirmed_user: user
    } do
      # Already confirmed users should get an error when trying to get a new token
      assert {:error, :already_confirmed} =
               Accounts.deliver_user_confirmation_instructions(user, & &1)
    end

    test "shows error for invalid token", %{conn: conn} do
      {:ok, _lv, html} =
        live(conn, ~p"/users/confirm/invalid-token")
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "Confirmation link is invalid or it has expired"
    end
  end
end
