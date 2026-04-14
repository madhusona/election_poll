defmodule ElectionPoll.Repo do
  use Ecto.Repo,
    otp_app: :election_poll,
    adapter: Ecto.Adapters.Postgres
end
