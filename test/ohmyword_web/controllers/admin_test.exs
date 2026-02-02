defmodule OhmywordWeb.AdminTest do
  use OhmywordWeb.ConnCase

  import Ohmyword.AccountsFixtures

  describe "GET /admin/dashboard" do
    test "redirects to login when not logged in", %{conn: conn} do
      conn = get(conn, "/admin/dashboard")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "redirects to home when logged in as member", %{conn: conn} do
      user = user_fixture()
      conn = conn |> log_in_user(user) |> get("/admin/dashboard")
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "You must be an admin"
    end

    test "shows dashboard when logged in as admin", %{conn: conn} do
      user = user_fixture()
      # Update user role to admin
      {:ok, user} = Ecto.Changeset.change(user, role: :admin) |> Ohmyword.Repo.update()

      conn = conn |> log_in_user(user) |> get("/admin/dashboard")
      assert html_response(conn, 200) =~ "Admin Dashboard"
      assert html_response(conn, 200) =~ "Kaffy"
    end
  end
end
