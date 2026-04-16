defmodule ElectionPoll.Elections do
  @moduledoc """
  The Elections context.
  """

  import Ecto.Query, warn: false
  alias ElectionPoll.Repo

  alias ElectionPoll.Accounts.Scope
  alias ElectionPoll.Elections.{State, Booth, Constituency, Candidate, Campaign}

  # ---------------------------------------------------------------------------
  # State
  # ---------------------------------------------------------------------------

  def subscribe_states(%Scope{} = scope) do
    key = scope.user.id
    Phoenix.PubSub.subscribe(ElectionPoll.PubSub, "user:#{key}:states")
  end

  defp broadcast_state(%Scope{} = scope, message) do
    key = scope.user.id
    Phoenix.PubSub.broadcast(ElectionPoll.PubSub, "user:#{key}:states", message)
  end

  def list_states(%Scope{} = _scope) do
    Repo.all(from s in State, where: s.is_active == true, order_by: [asc: s.name])
  end

  def count_active_candidates_by_constituency_ids(constituency_ids) do
    from(c in Candidate,
      where: c.constituency_id in ^constituency_ids and c.is_active == true,
      group_by: c.constituency_id,
      select: {c.constituency_id, count(c.id)}
    )
    |> Repo.all()
    |> Map.new()
  end

  def list_active_states_with_campaigns do
    from(s in State,
      join: cst in Constituency, on: cst.state_id == s.id,
      join: camp in Campaign, on: camp.constituency_id == cst.id,
      where: s.is_active == true and cst.is_active == true and camp.is_active == true,
      distinct: s.id,
      order_by: [asc: s.name],
      select: %{
        state_id: s.id,
        state_name: s.name,
        campaign_slug: camp.slug,
        campaign_name: camp.name
      }
    )
    |> Repo.all()
  end

  def list_active_campaigns do
    Campaign
    |> where([c], c.is_active == true)
    |> preload(constituency: [:state])
    |> Repo.all()
  end

  def get_state!(%Scope{} = scope, id) do
    Repo.get_by!(State, id: id, user_id: scope.user.id)
  end

  def create_state(%Scope{} = scope, attrs) do
    with {:ok, state = %State{}} <-
           %State{}
           |> State.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_state(scope, {:created, state})
      {:ok, state}
    end
  end

  def update_state(%Scope{} = scope, %State{} = state, attrs) do
    true = state.user_id == scope.user.id

    with {:ok, state = %State{}} <-
           state
           |> State.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_state(scope, {:updated, state})
      {:ok, state}
    end
  end

  def delete_state(%Scope{} = scope, %State{} = state) do
    true = state.user_id == scope.user.id

    with {:ok, state = %State{}} <- Repo.delete(state) do
      broadcast_state(scope, {:deleted, state})
      {:ok, state}
    end
  end

  def change_state(%Scope{} = scope, %State{} = state, attrs \\ %{}) do
    true = state.user_id == scope.user.id
    State.changeset(state, attrs, scope)
  end

  # ---------------------------------------------------------------------------
  # Constituency
  # ---------------------------------------------------------------------------

  def subscribe_constituencies(%Scope{} = scope) do
    key = scope.user.id
    Phoenix.PubSub.subscribe(ElectionPoll.PubSub, "user:#{key}:constituencies")
  end

  defp broadcast_constituency(%Scope{} = scope, message) do
    key = scope.user.id
    Phoenix.PubSub.broadcast(ElectionPoll.PubSub, "user:#{key}:constituencies", message)
  end

  def list_constituencies(%Scope{} = scope) do
    Repo.all_by(Constituency, user_id: scope.user.id)
  end

  # Keep this unscoped helper for dropdown/public flows where you already use it.
  def list_constituencies do
    Repo.all(from c in Constituency, order_by: [asc: c.name])
  end

  def get_constituency!(%Scope{} = scope, id) do
    Repo.get_by!(Constituency, id: id, user_id: scope.user.id)
  end

  def get_constituency_by_user!(user_id, constituency_id) do
    Repo.get_by!(Constituency, id: constituency_id, user_id: user_id)
  end

  def list_active_constituencies_by_user(user_id) do
    Constituency
    |> where([c], c.user_id == ^user_id and c.is_active == true)
    |> order_by([c], asc: c.display_order, asc: c.name)
    |> Repo.all()
  end

  def create_constituency(%Scope{} = scope, attrs) do
    with {:ok, constituency = %Constituency{}} <-
           %Constituency{}
           |> Constituency.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_constituency(scope, {:created, constituency})
      {:ok, constituency}
    end
  end

  def update_constituency(%Scope{} = scope, %Constituency{} = constituency, attrs) do
    true = constituency.user_id == scope.user.id

    with {:ok, constituency = %Constituency{}} <-
           constituency
           |> Constituency.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_constituency(scope, {:updated, constituency})
      {:ok, constituency}
    end
  end

  def delete_constituency(%Scope{} = scope, %Constituency{} = constituency) do
    true = constituency.user_id == scope.user.id

    with {:ok, constituency = %Constituency{}} <- Repo.delete(constituency) do
      broadcast_constituency(scope, {:deleted, constituency})
      {:ok, constituency}
    end
  end

  def change_constituency(%Scope{} = scope, %Constituency{} = constituency, attrs \\ %{}) do
    true = constituency.user_id == scope.user.id
    Constituency.changeset(constituency, attrs, scope)
  end

  # ---------------------------------------------------------------------------
  # Candidate
  # ---------------------------------------------------------------------------

  def subscribe_candidates(%Scope{} = scope) do
    key = scope.user.id
    Phoenix.PubSub.subscribe(ElectionPoll.PubSub, "user:#{key}:candidates")
  end

  defp broadcast_candidate(%Scope{} = scope, message) do
    key = scope.user.id
    Phoenix.PubSub.broadcast(ElectionPoll.PubSub, "user:#{key}:candidates", message)
  end

  def list_candidates(%Scope{} = scope) do
    Repo.all_by(Candidate, user_id: scope.user.id)
  end

  def get_candidate!(%Scope{} = scope, id) do
    Repo.get_by!(Candidate, id: id, user_id: scope.user.id)
  end

  def list_active_candidates_by_constituency(constituency_id) do
    Candidate
    |> where([c], c.constituency_id == ^constituency_id and c.is_active == true)
    |> order_by([c], asc: c.display_order)
    |> Repo.all()
  end

  def create_candidate(%Scope{} = scope, attrs) do
    with {:ok, candidate = %Candidate{}} <-
           %Candidate{}
           |> Candidate.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_candidate(scope, {:created, candidate})
      {:ok, candidate}
    end
  end

  def update_candidate(%Scope{} = scope, %Candidate{} = candidate, attrs) do
    true = candidate.user_id == scope.user.id

    with {:ok, candidate = %Candidate{}} <-
           candidate
           |> Candidate.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_candidate(scope, {:updated, candidate})
      {:ok, candidate}
    end
  end

  def delete_candidate(%Scope{} = scope, %Candidate{} = candidate) do
    true = candidate.user_id == scope.user.id

    with {:ok, candidate = %Candidate{}} <- Repo.delete(candidate) do
      broadcast_candidate(scope, {:deleted, candidate})
      {:ok, candidate}
    end
  end

  def list_active_constituencies_by_user_and_state(user_id, state_id) do
    Constituency
    |> where([c], c.user_id == ^user_id and c.state_id == ^state_id and c.is_active == true)
    |> order_by([c], asc: c.display_order, asc: c.name)
    |> Repo.all()
  end

  def change_candidate(%Scope{} = scope, %Candidate{} = candidate, attrs \\ %{}) do
    true = candidate.user_id == scope.user.id
    Candidate.changeset(candidate, attrs, scope)
  end

  # ---------------------------------------------------------------------------
  # Campaign
  # ---------------------------------------------------------------------------

  def subscribe_campaigns(%Scope{} = scope) do
    key = scope.user.id
    Phoenix.PubSub.subscribe(ElectionPoll.PubSub, "user:#{key}:campaigns")
  end

  defp broadcast_campaign(%Scope{} = scope, message) do
    key = scope.user.id
    Phoenix.PubSub.broadcast(ElectionPoll.PubSub, "user:#{key}:campaigns", message)
  end

  def list_campaigns(%Scope{} = scope) do
    Repo.all_by(Campaign, user_id: scope.user.id)
  end

  def get_campaign!(%Scope{} = scope, id) do
    Repo.get_by!(Campaign, id: id, user_id: scope.user.id)
  end

  def get_campaign_by_slug(slug) do
    Repo.get_by(Campaign, slug: slug, is_active: true)
  end

  def get_active_campaign_by_slug(slug) do
    Campaign
    |> Repo.get_by(slug: slug, is_active: true)
    |> Repo.preload(constituency: [:state])
  end

  def get_active_campaign_with_constituency_by_slug(slug) do
    Campaign
    |> Repo.get_by(slug: slug, is_active: true)
    |> Repo.preload(constituency: [:state])
  end

  def create_campaign(%Scope{} = scope, attrs) do
    with {:ok, campaign = %Campaign{}} <-
           %Campaign{}
           |> Campaign.changeset(attrs, scope)
           |> Repo.insert() do
      broadcast_campaign(scope, {:created, campaign})
      {:ok, campaign}
    end
  end

  def update_campaign(%Scope{} = scope, %Campaign{} = campaign, attrs) do
    true = campaign.user_id == scope.user.id

    with {:ok, campaign = %Campaign{}} <-
           campaign
           |> Campaign.changeset(attrs, scope)
           |> Repo.update() do
      broadcast_campaign(scope, {:updated, campaign})
      {:ok, campaign}
    end
  end

  def delete_campaign(%Scope{} = scope, %Campaign{} = campaign) do
    true = campaign.user_id == scope.user.id

    with {:ok, campaign = %Campaign{}} <- Repo.delete(campaign) do
      broadcast_campaign(scope, {:deleted, campaign})
      {:ok, campaign}
    end
  end

  def change_campaign(%Scope{} = scope, %Campaign{} = campaign, attrs \\ %{}) do
    if campaign.id do
      true = campaign.user_id == scope.user.id
    end

    Campaign.changeset(campaign, attrs, scope)
  end

  # ---------------------------------------------------------------------------
  # Booth
  # ---------------------------------------------------------------------------

  def list_booths(%Scope{} = scope) do
    Booth
    |> join(:inner, [b], c in Constituency, on: c.id == b.constituency_id)
    |> where([_b, c], c.user_id == ^scope.user.id)
    |> preload([_b, c], constituency: c)
    |> order_by([b, _c], asc: b.name)
    |> Repo.all()
  end

  def list_active_booths_by_constituency(constituency_id) do
    Repo.all(
      from b in Booth,
        where: b.constituency_id == ^constituency_id and b.status == "Active",
        order_by: [asc: b.name]
    )
  end

  def get_booth!(%Scope{} = scope, id) do
    Booth
    |> join(:inner, [b], c in Constituency, on: c.id == b.constituency_id)
    |> where([b, c], b.id == ^id and c.user_id == ^scope.user.id)
    |> preload([_b, c], constituency: c)
    |> Repo.one!()
  end

  def get_booth_by_constituency!(constituency_id, booth_id) do
    Repo.get_by!(Booth, id: booth_id, constituency_id: constituency_id)
  end

  def create_booth(%Scope{} = scope, attrs \\ %{}) do
    constituency_id = Map.get(attrs, "constituency_id") || Map.get(attrs, :constituency_id)
    _constituency = get_constituency!(scope, constituency_id)

    %Booth{}
    |> Booth.changeset(attrs)
    |> Repo.insert()
  end

  def update_booth(%Scope{} = scope, %Booth{} = booth, attrs) do
    _existing = get_booth!(scope, booth.id)

    constituency_id =
      Map.get(attrs, "constituency_id") ||
        Map.get(attrs, :constituency_id) ||
        booth.constituency_id

    _constituency = get_constituency!(scope, constituency_id)

    booth
    |> Booth.changeset(attrs)
    |> Repo.update()
  end

  def delete_booth(%Scope{} = scope, %Booth{} = booth) do
    _existing = get_booth!(scope, booth.id)
    Repo.delete(booth)
  end

  def change_booth(%Scope{} = scope, %Booth{} = booth, attrs \\ %{}) do
    if booth.id do
      _existing = get_booth!(scope, booth.id)
    end

    Booth.changeset(booth, attrs)
  end
end