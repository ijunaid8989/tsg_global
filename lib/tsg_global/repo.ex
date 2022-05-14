defmodule TsgGlobal.Repo do
  use Ecto.Repo,
    otp_app: :tsg_global,
    adapter: Ecto.Adapters.Postgres
end
