defmodule Boiler.Repo do
  use Ecto.Repo,
    otp_app: :boiler,
    adapter: Ecto.Adapters.Postgres
end
