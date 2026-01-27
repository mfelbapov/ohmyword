defmodule Ohmyword.Repo do
  use Ecto.Repo,
    otp_app: :ohmyword,
    adapter: Ecto.Adapters.Postgres
end
