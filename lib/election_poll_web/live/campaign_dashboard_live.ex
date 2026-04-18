defmodule ElectionPollWeb.CampaignDashboardLive do
  use ElectionPollWeb, :live_view

  import Ecto.Query

  alias ElectionPoll.Repo
  alias ElectionPoll.Polling.Response
  alias ElectionPoll.Elections.{State, Constituency, Candidate}
  alias ElectionPoll.Accounts.AccessControl

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    filters = default_filters()

    allowed_states = load_allowed_states(scope)
    allowed_constituencies = load_allowed_constituencies(scope, nil)

    {:ok,
     socket
     |> assign(:page_title, "Analytics Dashboard")
     |> assign(:filters, filters)
     |> assign(:allowed_states, allowed_states)
     |> assign(:allowed_constituencies, allowed_constituencies)
     |> load_dashboard(scope)}
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    scope = socket.assigns.current_scope

    normalized_filters = %{
      "state_id" => Map.get(filters, "state_id", ""),
      "constituency_id" => Map.get(filters, "constituency_id", ""),
      "gender" => Map.get(filters, "gender", ""),
      "age_group" => Map.get(filters, "age_group", "")
    }

    allowed_constituencies =
      load_allowed_constituencies(
        scope,
        blank_to_nil(normalized_filters["state_id"])
      )

    normalized_filters =
      if normalized_filters["constituency_id"] != "" and
           Enum.any?(allowed_constituencies, fn c ->
             to_string(c.id) == normalized_filters["constituency_id"]
           end) do
        normalized_filters
      else
        Map.put(normalized_filters, "constituency_id", "")
      end

    {:noreply,
     socket
     |> assign(:filters, normalized_filters)
     |> assign(:allowed_constituencies, allowed_constituencies)
     |> load_dashboard(scope)}
  end

  @impl true
  def handle_event("reset_filters", _params, socket) do
    scope = socket.assigns.current_scope
    filters = default_filters()
    allowed_constituencies = load_allowed_constituencies(scope, nil)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:allowed_constituencies, allowed_constituencies)
     |> load_dashboard(scope)}
  end

  defp default_filters do
    %{
      "state_id" => "",
      "constituency_id" => "",
      "gender" => "",
      "age_group" => ""
    }
  end

  defp load_dashboard(socket, scope) do
    filters = socket.assigns.filters
    base_query = restricted_query(scope, filters)

    total_votes = Repo.aggregate(base_query, :count, :id)

    candidate_stats =
      from(r in subquery(base_query),
        join: c in Candidate,
        on: c.id == r.candidate_id,
        group_by: [
          c.id,
          c.candidate_name,
          c.party_full_name,
          c.abbreviation,
          c.color,
          c.symbol_name,
          c.display_order
        ],
        order_by: [asc: c.display_order, asc: c.candidate_name],
        select: %{
          candidate_id: c.id,
          candidate_name: c.candidate_name,
          party_full_name: c.party_full_name,
          abbreviation: c.abbreviation,
          color: c.color,
          symbol_name: c.symbol_name,
          votes: count(r.id)
        }
      )
      |> Repo.all()

    candidate_results =
      Enum.map(candidate_stats, fn item ->
        percent =
          if total_votes > 0 do
            Float.round(item.votes * 100.0 / total_votes, 2)
          else
            0.0
          end

        Map.put(item, :percent, percent)
      end)

    gender_stats =
      from(r in subquery(base_query),
        group_by: r.gender,
        order_by: [asc: r.gender],
        select: %{
          gender: r.gender,
          count: count(r.id)
        }
      )
      |> Repo.all()

    age_stats =
      from(r in subquery(base_query),
        group_by: r.age_group,
        order_by: [asc: r.age_group],
        select: %{
          age_group: r.age_group,
          count: count(r.id)
        }
      )
      |> Repo.all()

    state_stats =
      from(r in subquery(base_query),
        join: ct in Constituency,
        on: ct.id == r.constituency_id,
        join: st in State,
        on: st.id == ct.state_id,
        group_by: [st.id, st.name],
        order_by: [asc: st.name],
        select: %{
          state_id: st.id,
          state_name: st.name,
          count: count(r.id)
        }
      )
      |> Repo.all()

    constituency_stats =
      from(r in subquery(base_query),
        join: ct in Constituency,
        on: ct.id == r.constituency_id,
        group_by: [ct.id, ct.name],
        order_by: [asc: ct.name],
        select: %{
          constituency_id: ct.id,
          constituency_name: ct.name,
          count: count(r.id)
        }
      )
      |> Repo.all()

    candidate_chart = %{
      categories: Enum.map(candidate_results, & &1.candidate_name),
      series: Enum.map(candidate_results, & &1.votes)
    }

    gender_chart = %{
      labels: Enum.map(gender_stats, &(&1.gender || "Unknown")),
      series: Enum.map(gender_stats, & &1.count)
    }

    age_chart = %{
      labels: Enum.map(age_stats, &(&1.age_group || "Unknown")),
      series: Enum.map(age_stats, & &1.count)
    }

    party_grouped =
      candidate_results
      |> Enum.group_by(&(&1.party_full_name || "Unknown"))
      |> Enum.map(fn {party_name, rows} ->
        %{
          party_name: party_name,
          votes: Enum.sum(Enum.map(rows, & &1.votes))
        }
      end)
      |> Enum.sort_by(&{-&1.votes, &1.party_name})

    party_chart = %{
      labels: Enum.map(party_grouped, & &1.party_name),
      series: Enum.map(party_grouped, & &1.votes)
    }

    trend_chart = %{
      categories: ["Current"],
      series: [total_votes]
    }

    summary = %{
      total_responses: total_votes,
      total_candidates: length(candidate_results),
      total_parties: length(party_grouped),
      leading_candidate:
        case candidate_results do
          [] -> nil
          rows -> rows |> Enum.max_by(& &1.votes) |> Map.get(:candidate_name)
        end
    }

    candidate_rows =
      Enum.map(candidate_results, fn row ->
        %{
          candidate_name: row.candidate_name,
          party_name: row.party_full_name,
          constituency_name: "—",
          vote_count: row.votes,
          vote_percent: row.percent
        }
      end)

    socket
    |> assign(:total_votes, total_votes)
    |> assign(:candidate_results, candidate_results)
    |> assign(:gender_stats, gender_stats)
    |> assign(:age_stats, age_stats)
    |> assign(:state_stats, state_stats)
    |> assign(:constituency_stats, constituency_stats)
    |> assign(:candidate_chart, candidate_chart)
    |> assign(:gender_chart, gender_chart)
    |> assign(:age_chart, age_chart)
    |> assign(:party_chart, party_chart)
    |> assign(:trend_chart, trend_chart)
    |> assign(:summary, summary)
    |> assign(:candidate_rows, candidate_rows)
  end

  defp restricted_query(%{user: %{role: "admin"}}, filters) do
    from(r in Response,
      join: ct in Constituency,
      on: ct.id == r.constituency_id,
      join: st in State,
      on: st.id == ct.state_id
    )
    |> apply_filters(filters)
  end

  defp restricted_query(%{user: user}, filters) do
    allowed = AccessControl.allowed_scope(user)

    query =
      from(r in Response,
        join: ct in Constituency,
        on: ct.id == r.constituency_id,
        join: st in State,
        on: st.id == ct.state_id
      )

    query =
      if Enum.empty?(allowed.campaign_ids) do
        query
      else
        where(query, [r, _ct, _st], r.campaign_id in ^allowed.campaign_ids)
      end

    query =
      if Enum.empty?(allowed.state_ids) do
        query
      else
        where(query, [_r, _ct, st], st.id in ^allowed.state_ids)
      end

    query =
      if Enum.empty?(allowed.constituency_ids) do
        query
      else
        where(query, [r, _ct, _st], r.constituency_id in ^allowed.constituency_ids)
      end

    query =
      if Map.has_key?(allowed, :device_fingerprints) and
           not Enum.empty?(allowed.device_fingerprints) do
        where(query, [r, _ct, _st], r.device_fingerprint in ^allowed.device_fingerprints)
      else
        query
      end

    query
    |> apply_filters(filters)
  end

  defp apply_filters(query, filters) do
    query
    |> maybe_filter_state(filters["state_id"])
    |> maybe_filter_constituency(filters["constituency_id"])
    |> maybe_filter_gender(filters["gender"])
    |> maybe_filter_age_group(filters["age_group"])
  end

  defp maybe_filter_state(query, nil), do: query
  defp maybe_filter_state(query, ""), do: query

  defp maybe_filter_state(query, state_id) do
    where(query, [_r, _ct, st], st.id == ^String.to_integer(state_id))
  end

  defp maybe_filter_constituency(query, nil), do: query
  defp maybe_filter_constituency(query, ""), do: query

  defp maybe_filter_constituency(query, constituency_id) do
    where(query, [r, _ct, _st], r.constituency_id == ^String.to_integer(constituency_id))
  end

  defp maybe_filter_gender(query, nil), do: query
  defp maybe_filter_gender(query, ""), do: query

  defp maybe_filter_gender(query, gender) do
    where(query, [r, _ct, _st], r.gender == ^gender)
  end

  defp maybe_filter_age_group(query, nil), do: query
  defp maybe_filter_age_group(query, ""), do: query

  defp maybe_filter_age_group(query, age_group) do
    where(query, [r, _ct, _st], r.age_group == ^age_group)
  end

  defp load_allowed_states(%{user: %{role: "admin"}}) do
    Repo.all(from s in State, order_by: [asc: s.name])
  end

  defp load_allowed_states(%{user: user}) do
    allowed = AccessControl.allowed_scope(user)

    query = from s in State, order_by: [asc: s.name]

    query =
      if Enum.empty?(allowed.state_ids) do
        query
      else
        where(query, [s], s.id in ^allowed.state_ids)
      end

    Repo.all(query)
  end

  defp load_allowed_constituencies(%{user: %{role: "admin"}}, state_id) do
    query =
      from ct in Constituency,
        join: st in State,
        on: st.id == ct.state_id,
        order_by: [asc: ct.name]

    query =
      if is_nil(state_id) do
        query
      else
        where(query, [ct, _st], ct.state_id == ^String.to_integer(state_id))
      end

    Repo.all(query)
  end

  defp load_allowed_constituencies(%{user: user}, state_id) do
    allowed = AccessControl.allowed_scope(user)

    query =
      from ct in Constituency,
        join: st in State,
        on: st.id == ct.state_id,
        order_by: [asc: ct.name]

    query =
      if Enum.empty?(allowed.state_ids) do
        query
      else
        where(query, [_ct, st], st.id in ^allowed.state_ids)
      end

    query =
      if Enum.empty?(allowed.constituency_ids) do
        query
      else
        where(query, [ct, _st], ct.id in ^allowed.constituency_ids)
      end

    query =
      if is_nil(state_id) do
        query
      else
        where(query, [ct, _st], ct.state_id == ^String.to_integer(state_id))
      end

    Repo.all(query)
  end

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value
end