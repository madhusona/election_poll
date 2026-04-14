defmodule ElectionPollWeb.AdminController do
  use ElectionPollWeb, :controller

  import Ecto.Query

  alias ElectionPoll.Repo
  alias ElectionPoll.Elections
  alias ElectionPoll.Elections.{Campaign, Booth, Constituency}
  alias ElectionPoll.Polling.Response

  def index(conn, _params) do
    scope = conn.assigns.current_scope
    user_id = scope.user.id

    constituencies_count =
      Elections.list_constituencies(scope)
      |> length()

    candidates_count =
      Elections.list_candidates(scope)
      |> length()

    campaigns =
      Elections.list_campaigns(scope)

    campaigns_count = length(campaigns)

    booths_count =
      from(b in Booth,
        join: con in Constituency, on: con.id == b.constituency_id,
        where: con.user_id == ^user_id,
        select: count(b.id)
      )
      |> Repo.one()

    responses_count =
      from(r in Response,
        join: cam in Campaign, on: cam.id == r.campaign_id,
        where: cam.user_id == ^user_id,
        select: count(r.id)
      )
      |> Repo.one()

    active_campaigns_count =
      Enum.count(campaigns, & &1.is_active)

    recent_campaigns =
      campaigns
      |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
      |> Enum.take(6)

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