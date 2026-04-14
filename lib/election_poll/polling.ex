defmodule ElectionPoll.Polling do
  @moduledoc """
  The Polling context.
  """

  import Ecto.Query, warn: false
  alias ElectionPoll.Repo

  alias ElectionPoll.Polling.Response
  alias ElectionPoll.Accounts.Scope
  alias ElectionPoll.Elections.Campaign
  alias ElectionPoll.Elections.Constituency
  alias ElectionPoll.Elections.Candidate

  @doc """
  Subscribes to scoped notifications about any response changes.

  The broadcasted messages match the pattern:

    * {:created, %Response{}}
    * {:updated, %Response{}}
    * {:deleted, %Response{}}
  """
  def subscribe_responses(%Scope{} = scope) do
    key = scope.user.id
    Phoenix.PubSub.subscribe(ElectionPoll.PubSub, "user:#{key}:responses")
  end

  defp broadcast_response(%Scope{} = scope, message) do
    key = scope.user.id
    Phoenix.PubSub.broadcast(ElectionPoll.PubSub, "user:#{key}:responses", message)
  end

  @doc """
  Returns the list of responses.
  """
  def list_responses(%Scope{} = scope) do
    Repo.all_by(Response, user_id: scope.user.id)
  end

  @doc """
  Gets a single response.
  """
  def get_response!(%Scope{} = scope, id) do
    Repo.get_by!(Response, id: id, user_id: scope.user.id)
  end

  @doc """
  Creates a response.
  """
  def create_response(%Scope{} = scope, attrs) do
    with {:ok, response = %Response{}} <-
           %Response{}
           |> Response.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_response(scope, {:created, response})
      {:ok, response}
    end
  end

  def create_response(attrs \\ %{}) do
    %Response{}
    |> Response.changeset(attrs)
    |> Repo.insert()
  end

  def count_votes(campaign_id, filters) do
    from(r in Response,
      where: r.campaign_id == ^campaign_id
    )
    |> apply_filters(filters)
    |> Repo.aggregate(:count)
  end

  def group_by_candidate(campaign_id, filters) do
    from(r in Response,
      where: r.campaign_id == ^campaign_id,
      group_by: r.candidate_id,
      select: {r.candidate_id, count(r.id)}
    )
    |> apply_filters(filters)
    |> Repo.all()
  end

  def group_by_gender(campaign_id, filters) do
    from(r in Response,
      where: r.campaign_id == ^campaign_id,
      group_by: r.gender,
      select: {r.gender, count(r.id)}
    )
    |> apply_filters(filters)
    |> Repo.all()
  end

  def group_by_age(campaign_id, filters) do
    from(r in Response,
      where: r.campaign_id == ^campaign_id,
      group_by: r.age_group,
      select: {r.age_group, count(r.id)}
    )
    |> apply_filters(filters)
    |> Repo.all()
  end

  defp apply_filters(query, filters) do
    query
    |> maybe_filter(:gender, filters[:gender])
    |> maybe_filter(:age_group, filters[:age_group])
    |> maybe_filter(:constituency_id, filters[:constituency_id])
    |> maybe_filter(:candidate_id, filters[:candidate_id])
  end

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, _field, ""), do: query

  defp maybe_filter(query, field, value) do
    where(query, [r], field(r, ^field) == ^value)
  end

  @doc """
  Updates a response.
  """
  def update_response(%Scope{} = scope, %Response{} = response, attrs) do
    true = response.user_id == scope.user.id

    with {:ok, response = %Response{}} <-
           response
           |> Response.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_response(scope, {:updated, response})
      {:ok, response}
    end
  end

  @doc """
  Deletes a response.
  """
  def delete_response(%Scope{} = scope, %Response{} = response) do
    true = response.user_id == scope.user.id

    with {:ok, response = %Response{}} <-
           Repo.delete(response) do
      broadcast_response(scope, {:deleted, response})
      {:ok, response}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking response changes.
  """
  def change_response(%Scope{} = scope, %Response{} = response, attrs \\ %{}) do
    true = response.user_id == scope.user.id
    Response.changeset(response, attrs, scope)
  end

  # ----------------------------------------------------------
  # ADMIN / SUBADMIN RESPONSE PAGE FUNCTIONS
  # ----------------------------------------------------------

  def list_responses_for_user(%{role: "admin"}, filters, limit, offset) do
    base_responses_query(filters)
    |> order_by([r, _camp, _cons, _cand], desc: r.inserted_at, desc: r.id)
    |> limit(^limit)
    |> offset(^offset)
    |> select([r, camp, cons, cand], %{
      id: r.id,
      vote_id: r.vote_id,
      submitted_at: r.submitted_at,
      campaign_id: camp.id,
      campaign_name: camp.name,
      constituency_id: cons.id,
      constituency_name: cons.name,
      booth_name: r.booth_name,
      candidate_id: cand.id,
      candidate_name: cand.candidate_name,
      party_full_name: cand.party_full_name,
      gender: r.gender,
      age_group: r.age_group,
      latitude: r.latitude,
      longitude: r.longitude,
      selfie_path: r.selfie_path,
      device_fingerprint: r.device_fingerprint
    })
    |> Repo.all()
  end

  def list_responses_for_user(%{role: "subadmin", id: user_id}, filters, limit, offset) do
    base_responses_query(filters)
    |> where([_r, camp, _cons, _cand], camp.assigned_user_id == ^user_id)
    |> order_by([r, _camp, _cons, _cand], desc: r.inserted_at, desc: r.id)
    |> limit(^limit)
    |> offset(^offset)
    |> select([r, camp, cons, cand], %{
      id: r.id,
      vote_id: r.vote_id,
      submitted_at: r.submitted_at,
      campaign_id: camp.id,
      campaign_name: camp.name,
      constituency_id: cons.id,
      constituency_name: cons.name,
      booth_name: r.booth_name,
      candidate_id: cand.id,
      candidate_name: cand.candidate_name,
      party_full_name: cand.party_full_name,
      gender: r.gender,
      age_group: r.age_group,
      latitude: r.latitude,
      longitude: r.longitude,
      selfie_path: nil,
      device_fingerprint: r.device_fingerprint
    })
    |> Repo.all()
  end

  def count_responses_for_user(%{role: "admin"}, filters) do
    base_responses_query(filters)
    |> select([r, _camp, _cons, _cand], count(r.id))
    |> Repo.one()
  end

  def count_responses_for_user(%{role: "subadmin", id: user_id}, filters) do
    base_responses_query(filters)
    |> where([_r, camp, _cons, _cand], camp.assigned_user_id == ^user_id)
    |> select([r, _camp, _cons, _cand], count(r.id))
    |> Repo.one()
  end

  def list_campaigns_for_response_filter(%{role: "admin"}) do
    from(c in Campaign,
      order_by: [asc: c.name],
      select: %{id: c.id, name: c.name}
    )
    |> Repo.all()
  end

  def list_campaigns_for_response_filter(%{role: "subadmin", id: user_id}) do
    from(c in Campaign,
      where: c.assigned_user_id == ^user_id,
      order_by: [asc: c.name],
      select: %{id: c.id, name: c.name}
    )
    |> Repo.all()
  end

  defp base_responses_query(filters) do
    campaign_id = blank_to_nil(filters["campaign_id"] || filters[:campaign_id])
    constituency_id = blank_to_nil(filters["constituency_id"] || filters[:constituency_id])
    candidate_id = blank_to_nil(filters["candidate_id"] || filters[:candidate_id])
    gender = blank_to_nil(filters["gender"] || filters[:gender])
    age_group = blank_to_nil(filters["age_group"] || filters[:age_group])

    from(r in Response,
      join: camp in Campaign, on: camp.id == r.campaign_id,
      left_join: cons in Constituency, on: cons.id == r.constituency_id,
      left_join: cand in Candidate, on: cand.id == r.candidate_id,
      where: is_nil(^campaign_id) or r.campaign_id == ^campaign_id,
      where: is_nil(^constituency_id) or r.constituency_id == ^constituency_id,
      where: is_nil(^candidate_id) or r.candidate_id == ^candidate_id,
      where: is_nil(^gender) or r.gender == ^gender,
      where: is_nil(^age_group) or r.age_group == ^age_group
    )
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end