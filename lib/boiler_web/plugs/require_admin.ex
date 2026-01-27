defmodule BoilerWeb.Plugs.RequireAdmin do
  @moduledoc """
  Plug that requires the current user to have admin role.

  This is part of a "Defense in Depth" strategy for Kaffy admin.
  """
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    # NOTE: This app uses current_scope pattern from phx.gen.auth
    # The user is accessed via conn.assigns.current_scope.user
    user = get_current_user(conn)

    if user && admin?(user) do
      conn
    else
      conn
      |> put_flash(:error, "You must be an admin to access this page.")
      |> redirect(to: "/")
      |> halt()
    end
  end

  defp get_current_user(conn) do
    case conn.assigns[:current_scope] do
      %{user: user} when not is_nil(user) -> user
      _ -> nil
    end
  end

  defp admin?(%{role: :admin}), do: true
  defp admin?(_), do: false
end
