defmodule ElectionPoll.Elections do
  import Ecto.Query, warn: false

  alias ElectionPoll.Repo
  alias ElectionPoll.Accounts.Scope
  alias ElectionPoll.Accounts.AccessControl
  alias ElectionPoll.Elections.{State, Constituency, Candidate, Campaign, Booth}

  ## -----------------------------
  ## helpers
  ## -----------------------------

  defp role_of(%Scope{user: user}) when is_atom(user.role), do: Atom.to_string(user.role)
  defp role_of(%Scope{user: user}) when is_binary(user.role), do: user.role
  defp role_of(_), do: "user"

  defp allowed_scope(scope), do: AccessControl.allowed_scope(scope.user)

  defp admin?(scope), do: role_of(scope) == "admin"
  defp subadmin?(scope), do: role_of(scope) == "subadmin"

  ## -----------------------------
  ## states
  ## -----------------------------

  def list_states do
    Repo.all(from s in State, order_by: [asc: s.name])
  end

  def list_states(%Scope{} = scope) do
    if admin?(scope) do
      list_states()
    else
      scope_data = allowed_scope(scope)

      query =
        from s in State,
          join: con in Constituency,
          on: con.state_id == s.id,
          distinct: s.id,
          order_by: [asc: s.name]

      query =
        cond do
          scope_data.state_ids != [] ->
            where(query, [s, _con], s.id in ^scope_data.state_ids)

          scope_data.constituency_ids != [] ->
            where(query, [_s, con], con.id in ^scope_data.constituency_ids)

          true ->
            where(query, [_s, _con], false)
        end

      Repo.all(query)
    end
  end

  def get_state!(id), do: Repo.get!(State, id)

  def create_state(attrs \\ %{}) do
    %State{}
    |> State.changeset(attrs)
    |> Repo.insert()
  end

  def update_state(%State{} = state, attrs) do
    state
    |> State.changeset(attrs)
    |> Repo.update()
  end

  def delete_state(%State{} = state) do
    Repo.delete(state)
  end

  def change_state(%State{} = state, attrs \\ %{}) do
    State.changeset(state, attrs)
  end

  ## -----------------------------
  ## constituency query
  ## -----------------------------

  defp constituency_query(%Scope{} = scope) do
    cond do
      admin?(scope) ->
        from con in Constituency,
          preload: [:state],
          order_by: [asc: con.display_order, asc: con.name]

      subadmin?(scope) ->
        scope_data = allowed_scope(scope)

        from con in Constituency,
          join: s in assoc(con, :state),
          where:
            con.id in ^scope_data.constituency_ids or
              (^scope_data.state_ids != [] and s.id in ^scope_data.state_ids),
          preload: [state: s],
          distinct: con.id,
          order_by: [asc: con.display_order, asc: con.name]

      true ->
        from con in Constituency,
          where: con.user_id == ^scope.user.id,
          preload: [:state],
          order_by: [asc: con.display_order, asc: con.name]
    end
  end

  ## -----------------------------
  ## constituencies
  ## -----------------------------

  def list_constituencies(%Scope{} = scope) do
    Repo.all(constituency_query(scope))
  end

  def get_constituency!(%Scope{} = scope, id) do
    constituency_query(scope)
    |> where([con], con.id == ^id)
    |> Repo.one!()
  end

  def create_constituency(%Scope{} = scope, attrs \\ %{}) do
    attrs =
      if admin?(scope) or subadmin?(scope) do
        attrs
      else
        Map.put(attrs, "user_id", scope.user.id)
      end

    %Constituency{}
    |> Constituency.changeset(attrs)
    |> Repo.insert()
  end

  def update_constituency(%Scope{} = scope, %Constituency{} = constituency, attrs) do
    _existing = get_constituency!(scope, constituency.id)

    constituency
    |> Constituency.changeset(attrs)
    |> Repo.update()
  end

  def delete_constituency(%Scope{} = scope, %Constituency{} = constituency) do
    _existing = get_constituency!(scope, constituency.id)
    Repo.delete(constituency)
  end

  def change_constituency(%Scope{} = scope, %Constituency{} = constituency, attrs \\ %{}) do
    if constituency.id, do: get_constituency!(scope, constituency.id)
    Constituency.changeset(constituency, attrs)
  end

  ## -----------------------------
  ## candidate query
  ## -----------------------------

  defp candidate_query(%Scope{} = scope) do
    cond do
      admin?(scope) ->
        from c in Candidate,
          join: con in assoc(c, :constituency),
          preload: [constituency: con],
          order_by: [asc: con.name, asc: c.candidate_name]

      subadmin?(scope) ->
        scope_data = allowed_scope(scope)

        from c in Candidate,
          join: con in assoc(c, :constituency),
          where: c.constituency_id in ^scope_data.constituency_ids,
          preload: [constituency: con],
          order_by: [asc: con.name, asc: c.candidate_name]

      true ->
        from c in Candidate,
          join: con in assoc(c, :constituency),
          where: c.user_id == ^scope.user.id,
          preload: [constituency: con],
          order_by: [asc: con.name, asc: c.candidate_name]
    end
  end

  ## -----------------------------
  ## candidates
  ## -----------------------------

  def list_candidates(%Scope{} = scope) do
    Repo.all(candidate_query(scope))
  end

  def list_active_candidates_by_constituency(constituency_id) do
    Candidate
    |> where([c], c.constituency_id == ^constituency_id and c.is_active == true)
    |> order_by([c], asc: c.display_order, asc: c.candidate_name)
    |> Repo.all()
  end

  def get_candidate!(%Scope{} = scope, id) do
    candidate_query(scope)
    |> where([c, _con], c.id == ^id)
    |> Repo.one!()
  end

  def create_candidate(%Scope{} = scope, attrs \\ %{}) do
    constituency_id = Map.get(attrs, "constituency_id") || Map.get(attrs, :constituency_id)
    _constituency = get_constituency!(scope, constituency_id)

    attrs =
      if admin?(scope) or subadmin?(scope) do
        attrs
      else
        Map.put(attrs, "user_id", scope.user.id)
      end

    %Candidate{}
    |> Candidate.changeset(attrs)
    |> Repo.insert()
  end

  def update_candidate(%Scope{} = scope, %Candidate{} = candidate, attrs) do
    _existing = get_candidate!(scope, candidate.id)

    constituency_id =
      Map.get(attrs, "constituency_id") ||
        Map.get(attrs, :constituency_id) ||
        candidate.constituency_id

    _constituency = get_constituency!(scope, constituency_id)

    candidate
    |> Candidate.changeset(attrs)
    |> Repo.update()
  end

  def delete_candidate(%Scope{} = scope, %Candidate{} = candidate) do
    _existing = get_candidate!(scope, candidate.id)
    Repo.delete(candidate)
  end

  def change_candidate(%Scope{} = scope, %Candidate{} = candidate, attrs \\ %{}) do
    if candidate.id, do: get_candidate!(scope, candidate.id)
    Candidate.changeset(candidate, attrs)
  end
  # -----------------------------------
  # ADMIN ONLY (NO SCOPE)
  # -----------------------------------

  def list_all_campaigns do
    Repo.all(from c in Campaign, order_by: [asc: c.name])
  end

  def list_all_states do
    Repo.all(from s in State, order_by: [asc: s.name])
  end

  def list_all_constituencies do
    Repo.all(from c in Constituency, order_by: [asc: c.name])
  end

  def list_all_booths do
    Repo.all(from b in Booth, order_by: [asc: b.name])
end
  ## -----------------------------
  ## campaign query
  ## -----------------------------

  defp campaign_query(%Scope{} = scope) do
    cond do
      admin?(scope) ->
        from cam in Campaign,
          join: con in assoc(cam, :constituency),
          preload: [constituency: con],
          order_by: [asc: cam.inserted_at]

      subadmin?(scope) ->
        scope_data = allowed_scope(scope)

        from cam in Campaign,
          join: con in assoc(cam, :constituency),
          where: cam.id in ^scope_data.campaign_ids,
          preload: [constituency: con],
          order_by: [asc: cam.inserted_at]

      true ->
        from cam in Campaign,
          join: con in assoc(cam, :constituency),
          where: cam.user_id == ^scope.user.id,
          preload: [constituency: con],
          order_by: [asc: cam.inserted_at]
    end
  end

  ## -----------------------------
  ## campaigns
  ## -----------------------------

  def list_campaigns(%Scope{} = scope) do
    Repo.all(campaign_query(scope))
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

  def get_campaign!(%Scope{} = scope, id) do
    campaign_query(scope)
    |> where([cam, _con], cam.id == ^id)
    |> Repo.one!()
  end

  

  def create_campaign(%Scope{} = scope, attrs \\ %{}) do
    constituency_id = Map.get(attrs, "constituency_id") || Map.get(attrs, :constituency_id)
    _constituency = get_constituency!(scope, constituency_id)

    attrs =
      if admin?(scope) or subadmin?(scope) do
        attrs
      else
        Map.put(attrs, "user_id", scope.user.id)
      end

    %Campaign{}
    |> Campaign.changeset(attrs)
    |> Repo.insert()
  end

  def update_campaign(%Scope{} = scope, %Campaign{} = campaign, attrs) do
    _existing = get_campaign!(scope, campaign.id)

    constituency_id =
      Map.get(attrs, "constituency_id") ||
        Map.get(attrs, :constituency_id) ||
        campaign.constituency_id

    _constituency = get_constituency!(scope, constituency_id)

    campaign
    |> Campaign.changeset(attrs)
    |> Repo.update()
  end

  def delete_campaign(%Scope{} = scope, %Campaign{} = campaign) do
    _existing = get_campaign!(scope, campaign.id)
    Repo.delete(campaign)
  end

  def change_campaign(%Scope{} = scope, %Campaign{} = campaign, attrs \\ %{}) do
    if campaign.id, do: get_campaign!(scope, campaign.id)
    Campaign.changeset(campaign, attrs)
  end

  ## -----------------------------
  ## booth query
  ## -----------------------------

  defp booth_query(%Scope{} = scope) do
    cond do
      admin?(scope) ->
        from b in Booth,
          join: con in assoc(b, :constituency),
          preload: [constituency: con],
          order_by: [asc: con.name, asc: b.name]

      subadmin?(scope) ->
        scope_data = allowed_scope(scope)

        from b in Booth,
          join: con in assoc(b, :constituency),
          where: b.constituency_id in ^scope_data.constituency_ids,
          preload: [constituency: con],
          order_by: [asc: con.name, asc: b.name]

      true ->
        from b in Booth,
          join: con in assoc(b, :constituency),
          where: con.user_id == ^scope.user.id,
          preload: [constituency: con],
          order_by: [asc: con.name, asc: b.name]
    end
  end

  ## -----------------------------
  ## booths
  ## -----------------------------

  def list_booths(%Scope{} = scope) do
    Repo.all(booth_query(scope))
  end

  def list_active_booths_by_constituency(constituency_id) do
    Repo.all(
      from b in Booth,
        where: b.constituency_id == ^constituency_id and b.status == "Active",
        order_by: [asc: b.name]
    )
  end

  def get_booth!(%Scope{} = scope, id) do
    booth_query(scope)
    |> where([booth, _con], booth.id == ^id)
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
    if booth.id, do: get_booth!(scope, booth.id)
    Booth.changeset(booth, attrs)
  end

  def list_active_states_with_campaigns do
    query = 
      from s in State,
        join: con in Constituency, on: con.state_id == s.id,
        join: cam in Campaign, on: cam.constituency_id == con.id,
        where: s.is_active == true and con.is_active == true and cam.is_active == true,
        distinct: s.id,
        order_by: [asc: s.display_order, asc: s.name],
        select: %{
          id: s.id,
          name: s.name,
          code: s.code,
          campaign_slug: cam.slug,
          campaign_name: cam.name
        }

    Repo.all(query)
  end

 

  ## -----------------------------
  ## public polling helpers
  ## -----------------------------

  

  

  def list_active_constituencies_by_state(state_id) do
    Repo.all(
      from con in Constituency,
        where: con.state_id == ^state_id and con.is_active == true,
        order_by: [asc: con.display_order, asc: con.name]
    )
  end

  def get_active_constituency!(id) do
    Repo.one!(
      from con in Constituency,
        where: con.id == ^id and con.is_active == true,
        preload: [:state]
    )
  end

  
  

  def count_active_candidates_by_constituency_ids(constituency_ids) when is_list(constituency_ids) do
    Repo.all(
      from c in Candidate,
        where: c.constituency_id in ^constituency_ids and c.is_active == true,
        group_by: c.constituency_id,
        select: {c.constituency_id, count(c.id)}
    )
    |> Map.new()
  end

  

  defp apply_scope_for_states_with_campaigns(query, %{user: %{role: role} = user} = scope) do
    case normalize_role(role) do
      "admin" ->
        query

      "subadmin" ->
        allowed_scope = ElectionPoll.Accounts.AccessControl.allowed_scope(user)

        from s in query,
          where: s.id in ^allowed_scope.state_ids

      _ ->
        from s in query,
          join: con in Constituency,
          on: con.state_id == s.id,
          join: cam in Campaign,
          on: cam.constituency_id == con.id,
          where: cam.user_id == ^user.id
    end
  end

  def get_constituency!(id), do: Repo.get!(Constituency, id)
  def list_booths_by_constituency(constituency_id) do
    Booth
    |> where([b], b.constituency_id == ^constituency_id)
    |> Repo.all()
  end
  def get_active_campaign_by_slug!(slug) do
    Campaign
    |> where([c], c.slug == ^slug and c.is_active == true)
    |> Repo.one!()
  end

  def get_booth!(id), do: Repo.get!(Booth, id)

  def get_active_campaign_by_slug!(slug) do
    Campaign
    |> where([c], c.slug == ^slug and c.is_active == true)
    |> Repo.one!()
  end

  def get_constituency!(id), do: Repo.get!(Constituency, id)

  def list_booths_by_constituency(constituency_id) do
    Booth
    |> where([b], b.constituency_id == ^constituency_id)
    |> Repo.all()
  end

  def get_booth!(id), do: Repo.get!(Booth, id)
  defp normalize_role(nil), do: "user"
  defp normalize_role(role) when is_atom(role), do: Atom.to_string(role)
  defp normalize_role(role) when is_binary(role), do: role

  ## -----------------------------
  ## public polling helpers
  ## -----------------------------

  def list_active_states_with_campaigns do
    query =
      from s in State,
        join: con in Constituency, on: con.state_id == s.id,
        join: cam in Campaign, on: cam.constituency_id == con.id,
        where:
          s.is_active == true and
            con.is_active == true and
            cam.is_active == true,
        distinct: s.id,
        order_by: [asc: s.display_order, asc: s.name],
        select: %{
          id: s.id,
          state_name: s.name,
          code: s.code,
          campaign_slug: cam.slug,
          campaign_name: cam.name
        }

    Repo.all(query)
  end

  def get_campaign_by_slug(slug) do
    Repo.get_by(Campaign, slug: slug, is_active: true)
  end

  def get_active_campaign_by_slug(slug) do
    Repo.one(
      from cam in Campaign,
        join: con in Constituency, on: con.id == cam.constituency_id,
        join: s in State, on: s.id == con.state_id,
        where:
          cam.slug == ^slug and
            cam.is_active == true and
            con.is_active == true and
            s.is_active == true,
        preload: [constituency: {con, state: s}]
    )
  end

  def get_active_campaign_with_constituency_by_slug(slug) do
    Repo.one(
      from cam in Campaign,
        join: con in Constituency, on: con.id == cam.constituency_id,
        join: s in State, on: s.id == con.state_id,
        where:
          cam.slug == ^slug and
            cam.is_active == true and
            con.is_active == true and
            s.is_active == true,
        preload: [constituency: {con, state: s}]
    )
  end

  def list_active_constituencies_by_state(state_id) do
    Repo.all(
      from con in Constituency,
        join: s in State, on: s.id == con.state_id,
        where:
          con.state_id == ^state_id and
            con.is_active == true and
            s.is_active == true,
        preload: [state: s],
        order_by: [asc: con.display_order, asc: con.name]
    )
  end

  def get_active_constituency!(id) do
    Repo.one!(
      from con in Constituency,
        join: s in State, on: s.id == con.state_id,
        where:
          con.id == ^id and
            con.is_active == true and
            s.is_active == true,
        preload: [state: s]
    )
  end

  def count_active_candidates_by_constituency_ids(constituency_ids) when is_list(constituency_ids) do
    if constituency_ids == [] do
      %{}
    else
      Repo.all(
        from c in Candidate,
          where:
            c.constituency_id in ^constituency_ids and
              c.status == "Active",
          group_by: c.constituency_id,
          select: {c.constituency_id, count(c.id)}
      )
      |> Map.new()
    end
  end

  def count_active_booths_by_constituency_ids(constituency_ids) when is_list(constituency_ids) do
    if constituency_ids == [] do
      %{}
    else
      Repo.all(
        from b in Booth,
          where:
            b.constituency_id in ^constituency_ids and
              b.status == "Active",
          group_by: b.constituency_id,
          select: {b.constituency_id, count(b.id)}
      )
      |> Map.new()
    end
  end

  

  def list_active_booths_by_constituency(constituency_id) do
    Repo.all(
      from b in Booth,
        where:
          b.constituency_id == ^constituency_id and
            b.status == "Active",
        order_by: [asc: b.name]
    )
  end
end

  