defmodule Grapexir.Repo do
  use Ecto.Repo,
    otp_app: :grapexir,
    adapter: Ecto.Adapters.Postgres
end
