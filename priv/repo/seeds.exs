# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Boiler.Repo.insert!(%Boiler.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

if Mix.env() != :test do
  alias Boiler.Accounts
  alias Boiler.Repo

  email = "a@a.a"
  password = "password"
  username = "username"

  if is_nil(Accounts.get_user_by_email(email)) do
    {:ok, user} =
      Accounts.register_user(%{
        email: email,
        password: password,
        username: username
      })

    # Update to admin role and confirm
    user
    |> Ecto.Changeset.change(role: :admin, confirmed_at: DateTime.utc_now(:second))
    |> Repo.update!()

    IO.puts("Admin user created: #{email} / #{password}")
  else
    IO.puts("Admin user already exists")
  end
end
