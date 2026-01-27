defmodule BoilerWeb.Admin do
  @moduledoc """
  Kaffy admin configuration module.

  Part of "Defense in Depth" strategy:
  1. Router pipeline (:admins_only) - first line of defense
  2. RequireAdmin plug - validates admin role
  3. This module's authorize_resource/1 - Kaffy-level check with LetMe policy

  NOTE: This app uses `current_scope` pattern from phx.gen.auth.
  The user is accessed via `conn.assigns.current_scope.user`, NOT `current_user`.
  """

  def create_resources(_conn) do
    [
      accounts: [
        resources: [
          user: [schema: Boiler.Accounts.User]
        ]
      ]
    ]
  end

  @doc """
  Kaffy authorization callback.

  Uses LetMe policy to authorize admin dashboard access.
  This is the innermost layer of defense - even if router/plug checks pass,
  this ensures the LetMe policy is satisfied.
  """
  def authorize_resource(conn) do
    # CRITICAL: This app uses current_scope pattern, NOT current_user
    user = get_current_user(conn)

    if user && Boiler.Policy.authorize_action?(:view_admin_dashboard, user, :user) do
      :ok
    else
      {:error, conn, "Unauthorized - Admin access required"}
    end
  end

  defp get_current_user(conn) do
    case conn.assigns[:current_scope] do
      %{user: user} when not is_nil(user) -> user
      _ -> nil
    end
  end
end
