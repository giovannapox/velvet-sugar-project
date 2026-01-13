defmodule LojaVirtual.Repo do
  use Ecto.Repo,
    otp_app: :loja_virtual,
    adapter: Ecto.Adapters.Postgres
end
