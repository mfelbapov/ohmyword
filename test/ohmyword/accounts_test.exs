defmodule Ohmyword.AccountsTest do
  use Ohmyword.DataCase

  alias Ohmyword.Accounts

  import Ohmyword.AccountsFixtures
  alias Ohmyword.Accounts.{User, UserToken}

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture() |> set_password()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture() |> set_password()

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end

    test "returns error for unconfirmed user with valid credentials" do
      user = unconfirmed_user_fixture()

      assert {:error, :unconfirmed} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "change_user_login/1" do
    test "returns a user changeset for login validation" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_login()
      assert :email in changeset.required
      assert :password in changeset.required
    end

    test "validates email format" do
      changeset = Accounts.change_user_login(%{"email" => "invalid"})
      changeset = %{changeset | action: :validate}

      assert %{email: ["must be a valid email address"]} = errors_on(changeset)
    end

    test "validates email is required" do
      changeset = Accounts.change_user_login(%{"email" => ""})
      changeset = %{changeset | action: :validate}

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates password is required" do
      changeset = Accounts.change_user_login(%{"email" => "test@example.com", "password" => ""})
      changeset = %{changeset | action: :validate}

      assert %{password: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email max length" do
      too_long = String.duplicate("db", 100)
      changeset = Accounts.change_user_login(%{"email" => too_long})
      changeset = %{changeset | action: :validate}

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "normalizes email by downcasing and trimming" do
      email = "  User@EXAMPLE.Com  "
      changeset = Accounts.change_user_login(%{"email" => email, "password" => "pass"})

      assert get_change(changeset, :email) == "user@example.com"
    end

    test "does not validate password length or strength for login" do
      # Login validation only checks presence, not strength
      changeset = Accounts.change_user_login(%{"email" => "test@example.com", "password" => "x"})
      changeset = %{changeset | action: :validate}

      # Should be valid even with a short password (actual validation happens server-side)
      refute Map.has_key?(errors_on(changeset), :password)
    end

    test "does not check if email exists in database" do
      # This is important for security - we don't want to reveal if an email is registered
      changeset =
        Accounts.change_user_login(%{"email" => "nonexistent@example.com", "password" => "pass"})

      changeset = %{changeset | action: :validate}

      # Should be valid even if email doesn't exist
      refute Map.has_key?(errors_on(changeset), :email)
    end
  end

  describe "register_user/1" do
    test "requires email and username to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{email: ["can't be blank"], username: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid"})

      assert %{email: ["must be a valid email address"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(valid_user_attributes(email: email))
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} =
        Accounts.register_user(valid_user_attributes(email: String.upcase(email)))

      assert "has already been taken" in errors_on(changeset).email
    end

    test "normalizes email by downcasing and trimming" do
      email = "  User@EXAMPLE.Com  "
      {:ok, user} = Accounts.register_user(valid_user_attributes(email: email))
      assert user.email == "user@example.com"
    end

    test "registers users with password and username" do
      email = unique_user_email()
      username = "valid_user"

      {:ok, user} =
        Accounts.register_user(valid_user_attributes(email: email, username: username))

      assert user.email == email
      assert user.username == username
      assert user.role == :member
      assert user.hashed_password
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end

    test "validates username length" do
      {:error, changeset} = Accounts.register_user(valid_user_attributes(username: "ab"))
      assert "should be at least 3 character(s)" in errors_on(changeset).username

      {:error, changeset} =
        Accounts.register_user(valid_user_attributes(username: "this_username_is_way_too_long"))

      assert "should be at most 20 character(s)" in errors_on(changeset).username
    end

    test "validates username format" do
      {:error, changeset} =
        Accounts.register_user(valid_user_attributes(username: "invalid user"))

      assert "only letters, numbers, underscores, and hyphens allowed" in errors_on(changeset).username
    end

    test "validates username uniqueness" do
      %{username: username} = user_fixture()
      {:error, changeset} = Accounts.register_user(valid_user_attributes(username: username))
      assert "has already been taken" in errors_on(changeset).username

      {:error, changeset} =
        Accounts.register_user(valid_user_attributes(username: String.upcase(username)))

      assert "has already been taken" in errors_on(changeset).username
    end

    test "normalizes username" do
      username = "User_Name"
      {:ok, user} = Accounts.register_user(valid_user_attributes(username: username))
      assert user.username == "user_name"
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.utc_now()})
      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute Accounts.sudo_mode?(
               %User{authenticated_at: DateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute Accounts.sudo_mode?(%User{})
    end
  end

  describe "change_user_email/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end

    test "normalizes email when changing" do
      user = user_fixture()
      new_email = "  NewEmail@EXAMPLE.Com  "
      changeset = Accounts.change_user_email(user, %{email: new_email})
      assert get_change(changeset, :email) == "newemail@example.com"
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = unconfirmed_user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert {:ok, %{email: ^email}} = Accounts.update_user_email(user, token)
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Accounts.update_user_email(user, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(
          %User{},
          %{
            "password" => "validpass1"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "validpass1"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, %{
          password: "short",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 8 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, {user, _expired_tokens}} =
        Accounts.update_user_password(user, %{
          password: "validpass1"
        })

      # expired_tokens may include confirmation tokens that haven't been cleaned up
      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "validpass1")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, {_, _}} =
        Accounts.update_user_password(user, %{
          password: "validpass1"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"
      assert user_token.authenticated_at != nil

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end

    test "duplicates the authenticated_at of given user in new token", %{user: user} do
      user = %{user | authenticated_at: DateTime.add(DateTime.utc_now(:second), -3600)}
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.authenticated_at == user.authenticated_at
      assert DateTime.compare(user_token.inserted_at, user.authenticated_at) == :gt
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert {session_user, token_inserted_at} = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
      assert session_user.authenticated_at != nil
      assert token_inserted_at != nil
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      dt = ~N[2020-01-01 00:00:00]

      {1, nil} =
        Repo.update_all(from(t in UserToken, where: t.context == "session"),
          set: [inserted_at: dt, authenticated_at: dt]
        )

      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_user_confirmation_instructions/2" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_confirmation_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm"
    end

    test "does not send confirmation for already confirmed user" do
      user = user_fixture()

      assert {:error, :already_confirmed} =
               Accounts.deliver_user_confirmation_instructions(user, & &1)
    end
  end

  describe "confirm_user/1" do
    test "confirms user with valid token" do
      user = unconfirmed_user_fixture()
      refute user.confirmed_at

      {encoded_token, _hashed_token} = generate_user_confirmation_token(user)
      assert {:ok, confirmed_user} = Accounts.confirm_user(encoded_token)
      assert confirmed_user.confirmed_at
      assert confirmed_user.id == user.id
    end

    test "does not confirm with invalid token" do
      assert {:error, :invalid} = Accounts.confirm_user("invalid")
    end

    test "does not confirm with expired token" do
      user = unconfirmed_user_fixture()
      {encoded_token, _hashed_token} = generate_user_confirmation_token(user)

      {1, nil} =
        Repo.update_all(
          from(t in UserToken, where: t.context == "confirm" and t.user_id == ^user.id),
          set: [inserted_at: ~N[2020-01-01 00:00:00]]
        )

      assert {:error, _reason} = Accounts.confirm_user(encoded_token)
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
