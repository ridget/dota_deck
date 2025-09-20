defmodule DotaDeck.Repo do
  use Ecto.Repo,
    otp_app: :dota_deck,
    adapter: Ecto.Adapters.Postgres
end
