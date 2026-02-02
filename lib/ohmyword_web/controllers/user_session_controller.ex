defmodule OhmywordWeb.UserSessionController do
  use OhmywordWeb, :controller

  alias Ohmyword.Accounts
  alias OhmywordWeb.UserAuth

  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    case Accounts.get_user_by_email_and_password(email, password) do
      %Ohmyword.Accounts.User{} = user ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> UserAuth.log_in_user(user, user_params)

      {:error, :unconfirmed} ->
        conn
        |> put_flash(
          :error,
          "You must confirm your email before logging in. Please check your email for confirmation instructions."
        )
        |> put_flash(:email, String.slice(email, 0, 160))
        |> redirect(to: ~p"/users/resend-confirmation")

      nil ->
        # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
        conn
        |> put_flash(:error, "Invalid email or password")
        |> put_flash(:email, String.slice(email, 0, 160))
        |> redirect(to: ~p"/users/log-in")
    end
  end

  def update_password(conn, %{"user" => user_params}) do
    user = conn.assigns.current_scope.user

    unless Accounts.sudo_mode?(user) do
      conn
      |> put_flash(:error, "Please re-authenticate to update your password.")
      |> redirect(to: ~p"/users/log-in")
    else
      case Accounts.update_user_password(user, user_params) do
        {:ok, {user, expired_tokens}} ->
          # disconnect all existing LiveViews with old sessions
          UserAuth.disconnect_sessions(expired_tokens)

          conn
          |> put_flash(:info, "Password updated successfully!")
          |> put_session(:user_return_to, ~p"/users/settings")
          |> UserAuth.log_in_user(user, user_params)

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Failed to update password. Please check your input.")
          |> redirect(to: ~p"/users/settings")
      end
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
