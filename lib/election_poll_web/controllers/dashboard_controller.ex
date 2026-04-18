defmodule ElectionPollWeb.DashboardController do
  use ElectionPollWeb, :controller

  import Ecto.Query

  alias ElectionPoll.Repo
  alias ElectionPoll.Elections.{Campaign, Booth, Constituency, Candidate}
  alias ElectionPoll.Polling.Response
  alias ElectionPoll.Accounts.AccessControl

  def index(conn, _params) do
    current_user = conn.assigns.current_scope.user
    user_role = normalize_role(current_user.role)
    allowed_scope = AccessControl.allowed_scope(current_user)

    campaigns_query =
      from cam in Campaign,
        join: con in Constituency, on: con.id == cam.constituency_id,
        where: ^campaign_scope_filter(user_role, current_user.id, allowed_scope),
        order_by: [desc: cam.inserted_at],
        select: cam

    campaigns = Repo.all(campaigns_query)

    constituencies_count =
      from(con in Constituency,
        join: cam in Campaign, on: cam.constituency_id == con.id,
        where: ^campaign_scope_filter(user_role, current_user.id, allowed_scope),
        distinct: con.id,
        select: con.id
      )
      |> Repo.aggregate(:count)

    candidates_count =
      from(c in Candidate,
        join: cam in Campaign, on: cam.id == c.campaign_id,
        join: con in Constituency, on: con.id == cam.constituency_id,
        where: ^campaign_scope_filter(user_role, current_user.id, allowed_scope),
        select: count(c.id)
      )
      |> Repo.one()

    booths_count =
      from(b in Booth,
        join: con in Constituency, on: con.id == b.constituency_id,
        join: cam in Campaign, on: cam.constituency_id == con.id,
        where: ^campaign_scope_filter(user_role, current_user.id, allowed_scope),
        distinct: b.id,
        select: count(b.id)
      )
      |> Repo.one()

    responses_count =
      from(r in Response,
        join: cam in Campaign, on: cam.id == r.campaign_id,
        join: con in Constituency, on: con.id == cam.constituency_id,
        where: ^campaign_scope_filter(user_role, current_user.id, allowed_scope),
        select: count(r.id)
      )
      |> Repo.one()

    campaigns_count = length(campaigns)
    active_campaigns_count = Enum.count(campaigns, & &1.is_active)
    recent_campaigns = Enum.take(campaigns, 6)

    render(conn, :index,
      constituencies_count: constituencies_count,
      candidates_count: candidates_count || 0,
      booths_count: booths_count || 0,
      campaigns_count: campaigns_count,
      responses_count: responses_count || 0,
      active_campaigns_count: active_campaigns_count,
      recent_campaigns: recent_campaigns
    )
  end

  defp campaign_scope_filter("admin", _user_id, _allowed_scope) do
    dynamic([cam, con], not is_nil(cam.id) and not is_nil(con.id))
  end

  defp campaign_scope_filter("subadmin", _user_id, %{campaign_ids: []}) do
    dynamic([_cam, _con], false)
  end

  defp campaign_scope_filter("subadmin", _user_id, allowed_scope) do
    dynamic(
      [cam, con],
      cam.id in ^allowed_scope.campaign_ids and
        (^Enum.empty?(allowed_scope.constituency_ids) or con.id in ^allowed_scope.constituency_ids)
    )
  end

  defp campaign_scope_filter(_, user_id, _allowed_scope) do
    dynamic([cam, _con], cam.user_id == ^user_id)
  end

  defp normalize_role(nil), do: "user"
  defp normalize_role(role) when is_atom(role), do: Atom.to_string(role)
  defp normalize_role(role) when is_binary(role), do: role
end