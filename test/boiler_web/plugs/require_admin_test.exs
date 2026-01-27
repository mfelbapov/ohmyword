defmodule BoilerWeb.Plugs.RequireAdminTest do
  use BoilerWeb.ConnCase, async: true

  alias BoilerWeb.Plugs.RequireAdmin
  alias Boiler.Accounts.Scope
  import Boiler.AccountsFixtures

  describe "call/2" do
    test "allows admin users through", %{conn: conn} do
      user = user_fixture()
      {:ok, admin_user} = Ecto.Changeset.change(user, role: :admin) |> Boiler.Repo.update()
      scope = Scope.for_user(admin_user)

      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> Plug.Conn.assign(:current_scope, scope)
        |> fetch_flash()
        |> RequireAdmin.call([])

      refute conn.halted
    end

    test "redirects non-admin users with flash message", %{conn: conn} do
      user = user_fixture()
      scope = Scope.for_user(user)

      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> Plug.Conn.assign(:current_scope, scope)
        |> fetch_flash()
        |> RequireAdmin.call([])

      assert conn.halted
      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must be an admin to access this page."
    end

    test "redirects unauthenticated users", %{conn: conn} do
      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> fetch_flash()
        |> RequireAdmin.call([])

      assert conn.halted
      assert redirected_to(conn) == "/"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must be an admin to access this page."
    end

    test "handles nil current_scope", %{conn: conn} do
      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> Plug.Conn.assign(:current_scope, nil)
        |> fetch_flash()
        |> RequireAdmin.call([])

      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "handles current_scope with nil user", %{conn: conn} do
      conn =
        conn
        |> Phoenix.ConnTest.init_test_session(%{})
        |> Plug.Conn.assign(:current_scope, %{user: nil})
        |> fetch_flash()
        |> RequireAdmin.call([])

      assert conn.halted
      assert redirected_to(conn) == "/"
    end
  end

  describe "init/1" do
    test "returns opts unchanged" do
      assert RequireAdmin.init(foo: :bar) == [foo: :bar]
    end
  end
end
