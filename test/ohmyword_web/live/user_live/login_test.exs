defmodule OhmywordWeb.UserLive.LoginTest do
  use OhmywordWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Ohmyword.AccountsFixtures

  describe "login page" do
    test "renders login page", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "Log in"
      assert html =~ "Register"
    end
  end

  describe "user login - password" do
    test "redirects if user logs in with valid credentials", %{conn: conn} do
      user = user_fixture()

      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form =
        form(lv, "#login_form",
          user: %{email: user.email, password: valid_user_password(), remember_me: true}
        )

      conn = submit_form(form, conn)

      assert redirected_to(conn) == ~p"/"
    end

    test "redirects to login page with a flash error if credentials are invalid", %{
      conn: conn
    } do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      form =
        form(lv, "#login_form", user: %{email: "test@email.com", password: "123456"})

      render_submit(form, %{user: %{remember_me: true}})

      conn = follow_trigger_action(form, conn)
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid email or password"
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end

  describe "inline validation" do
    test "validates email format on change", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      html =
        lv
        |> form("#login_form", user: %{email: "invalid-email", password: ""})
        |> render_change()

      assert html =~ "must be a valid email address"
    end

    test "validates email is required", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      html =
        lv
        |> form("#login_form", user: %{email: "", password: "somepass"})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "validates password is required", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      html =
        lv
        |> form("#login_form", user: %{email: "test@example.com", password: ""})
        |> render_change()

      assert html =~ "can&#39;t be blank"
    end

    test "does not validate password strength for login", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      # Short password should be accepted for format validation
      # (actual password verification happens server-side)
      html =
        lv
        |> form("#login_form", user: %{email: "test@example.com", password: "x"})
        |> render_change()

      # Should not show password length errors
      refute html =~ "should be at least"
    end

    test "clears validation errors when valid input is provided", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      # First, trigger an error
      html =
        lv
        |> form("#login_form", user: %{email: "invalid", password: ""})
        |> render_change()

      assert html =~ "must be a valid email address"

      # Now fix it
      html =
        lv
        |> form("#login_form", user: %{email: "test@example.com", password: "pass"})
        |> render_change()

      refute html =~ "must be a valid email address"
    end
  end

  describe "login navigation" do
    test "redirects to registration page when the Register button is clicked", %{conn: conn} do
      {:ok, lv, _html} = live(conn, ~p"/users/log-in")

      {:ok, _login_live, login_html} =
        lv
        |> element("main a", "Sign up")
        |> render_click()
        |> follow_redirect(conn, ~p"/users/register")

      assert login_html =~ "Register"
    end
  end

  describe "re-authentication (sudo mode)" do
    setup %{conn: conn} do
      user = user_fixture()
      %{user: user, conn: log_in_user(conn, user)}
    end

    test "shows login page with email filled in", %{conn: conn, user: user} do
      {:ok, _lv, html} = live(conn, ~p"/users/log-in")

      assert html =~ "You need to reauthenticate"
      refute html =~ "Register"

      assert html =~
               ~s(<input type="email" name="user[email]" id="login_form_email" value="#{user.email}")
    end
  end
end
