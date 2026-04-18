defmodule ElectionPollWeb.AdminController do
  use ElectionPollWeb, :controller

  import Ecto.Query

  alias ElectionPoll.Repo
  alias ElectionPoll.Elections.{Campaign, Booth, Constituency, Candidate}
  alias ElectionPoll.Polling.Response

  def index(conn, _params) do
    campaigns =
      from(c in Campaign, order_by: [desc: c.inserted_at])
      |> Repo.all()

    constituencies_count = Repo.aggregate(Constituency, :count, :id)
    candidates_count = Repo.aggregate(Candidate, :count, :id)
    booths_count = Repo.aggregate(Booth, :count, :id)
    responses_count = Repo.aggregate(Response, :count, :id)

    campaigns_count = length(campaigns)
    active_campaigns_count = Enum.count(campaigns, & &1.is_active)
    recent_campaigns = Enum.take(campaigns, 6)

    render(conn, :index,
      constituencies_count: constituencies_count,
      candidates_count: candidates_count,
      booths_count: booths_count,
      campaigns_count: campaigns_count,
      responses_count: responses_count,
      active_campaigns_count: active_campaigns_count,
      recent_campaigns: recent_campaigns
    )
  end
end