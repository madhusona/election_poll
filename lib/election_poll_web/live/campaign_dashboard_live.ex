defmodule ElectionPollWeb.CampaignDashboardLive do
  use ElectionPollWeb, :live_view

  import Ecto.Query

  alias ElectionPoll.Repo
  alias ElectionPoll.Elections
  alias ElectionPoll.Polling.Response
  alias ElectionPoll.Elections.Candidate

  @top_booth_limit 10
  @high_zoom_point_limit 2000

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    campaign_id = String.to_integer(id)

    if connected?(socket) do
      ElectionPollWeb.Endpoint.subscribe("campaign:#{campaign_id}")
    end

    socket =
      socket
      |> assign(:campaign_id, campaign_id)
      |> assign(:page_title, "Campaign Dashboard")
      |> assign(:map_mode, "cluster")
      |> assign(:map_payload, [])
      |> load_dashboard_data()

    {:ok, socket}
  end

  @impl true
  def handle_info(%{event: "new_vote"}, socket) do
    socket = load_dashboard_data(socket)

    socket =
      push_event(socket, "update_charts", %{
        candidate_stats: socket.assigns.candidate_stats,
        gender_stats: socket.assigns.gender_stats,
        age_stats: socket.assigns.age_stats,
        party_stats: socket.assigns.party_stats,
        trend_stats: socket.assigns.trend_stats,
        booth_turnout_stats: socket.assigns.booth_turnout_stats,
        booth_leaders: socket.assigns.booth_leaders
      })

    {:noreply, socket}
  end

  @impl true
  def handle_event("map_view_changed", params, socket) do
    north = parse_float(params["north"])
    south = parse_float(params["south"])
    east = parse_float(params["east"])
    west = parse_float(params["west"])
    zoom = parse_int(params["zoom"])

    {mode, payload} =
      fetch_map_data(
        socket.assigns.campaign_id,
        socket.assigns.current_scope,
        north,
        south,
        east,
        west,
        zoom
      )

    socket =
      socket
      |> assign(:map_mode, mode)
      |> assign(:map_payload, payload)
      |> push_event("update_map_layer", %{
        mode: mode,
        payload: payload
      })

    {:noreply, socket}
  end

  defp load_dashboard_data(socket) do
    scope = socket.assigns.current_scope
    campaign_id = socket.assigns.campaign_id

    campaign = Elections.get_campaign!(scope, campaign_id)

    total_votes =
      from(r in Response,
        where: r.campaign_id == ^campaign.id
      )
      |> Repo.aggregate(:count, :id)

    candidate_stats =
      from(r in Response,
        join: c in Candidate, on: c.id == r.candidate_id,
        where: r.campaign_id == ^campaign.id,
        group_by: [
          r.candidate_id,
          c.candidate_name,
          c.party_full_name,
          c.abbreviation,
          c.color,
          c.symbol_name,
          c.alliance
        ],
        order_by: [desc: count(r.id)],
        select: %{
          candidate_id: r.candidate_id,
          candidate_name: c.candidate_name,
          party_full_name: c.party_full_name,
          abbreviation: c.abbreviation,
          color: c.color,
          symbol_name: c.symbol_name,
          alliance: c.alliance,
          votes: count(r.id)
        }
      )
      |> Repo.all()

    top_candidate = List.first(candidate_stats)

    gender_stats =
      from(r in Response,
        where: r.campaign_id == ^campaign.id,
        group_by: r.gender,
        order_by: r.gender,
        select: %{label: r.gender, value: count(r.id)}
      )
      |> Repo.all()

    age_stats =
      from(r in Response,
        where: r.campaign_id == ^campaign.id,
        group_by: r.age_group,
        order_by: r.age_group,
        select: %{label: r.age_group, value: count(r.id)}
      )
      |> Repo.all()

    party_stats =
      from(r in Response,
        join: c in Candidate, on: c.id == r.candidate_id,
        where: r.campaign_id == ^campaign.id,
        group_by: [c.party_full_name, c.color],
        order_by: [desc: count(r.id)],
        select: %{
          party: c.party_full_name,
          color: c.color,
          votes: count(r.id)
        }
      )
      |> Repo.all()

    trend_stats =
      from(r in Response,
        where: r.campaign_id == ^campaign.id,
        group_by: fragment("date_trunc('minute', ?)", r.inserted_at),
        order_by: fragment("date_trunc('minute', ?)", r.inserted_at),
        select: %{
          time: fragment("to_char(date_trunc('minute', ?), 'HH24:MI')", r.inserted_at),
          votes: count(r.id)
        }
      )
      |> Repo.all()

    booth_turnout_stats =
      from(r in Response,
        where:
          r.campaign_id == ^campaign.id and
            not is_nil(r.booth_name) and
            r.booth_name != "",
        group_by: r.booth_name,
        order_by: [desc: count(r.id)],
        select: %{
          booth_name: r.booth_name,
          votes: count(r.id)
        }
      )
      |> Repo.all()

    booth_candidate_stats =
      from(r in Response,
        join: c in Candidate, on: c.id == r.candidate_id,
        where:
          r.campaign_id == ^campaign.id and
            not is_nil(r.booth_name) and
            r.booth_name != "",
        group_by: [r.booth_name, c.candidate_name, c.color],
        select: %{
          booth_name: r.booth_name,
          candidate_name: c.candidate_name,
          color: c.color,
          votes: count(r.id)
        }
      )
      |> Repo.all()

    booth_leaders =
      booth_candidate_stats
      |> Enum.group_by(& &1.booth_name)
      |> Enum.map(fn {booth_name, stats} ->
        leader = Enum.max_by(stats, & &1.votes)

        %{
          booth_name: booth_name,
          candidate_name: leader.candidate_name,
          color: leader.color,
          votes: leader.votes
        }
      end)
      |> Enum.sort_by(& &1.votes, :desc)

    top_booths = Enum.take(booth_turnout_stats, @top_booth_limit)

    socket
    |> assign(:campaign, campaign)
    |> assign(:total_votes, total_votes)
    |> assign(:candidate_stats, candidate_stats)
    |> assign(:top_candidate, top_candidate)
    |> assign(:gender_stats, gender_stats)
    |> assign(:age_stats, age_stats)
    |> assign(:party_stats, party_stats)
    |> assign(:trend_stats, trend_stats)
    |> assign(:booth_turnout_stats, booth_turnout_stats)
    |> assign(:booth_leaders, booth_leaders)
    |> assign(:top_booths, top_booths)
  end

  defp candidate_clusters(campaign_id, north, south, east, west, zoom) do
    cell =
      cond do
        zoom <= 8 -> 0.05
        zoom <= 10 -> 0.03
        zoom <= 12 -> 0.02
        true -> 0.01
      end

    # STEP 1: Bucket votes
    bucketed =
      from(r in Response,
        join: c in Candidate, on: c.id == r.candidate_id,
        where:
          r.campaign_id == ^campaign_id and
            not is_nil(r.latitude) and
            not is_nil(r.longitude) and
            r.latitude >= ^south and r.latitude <= ^north and
            r.longitude >= ^west and r.longitude <= ^east,
        select: %{
          lat_bucket: fragment("floor(? / ?) * ?", r.latitude, ^cell, ^cell),
          lng_bucket: fragment("floor(? / ?) * ?", r.longitude, ^cell, ^cell),
          candidate_name: c.candidate_name,
          candidate_color: c.color
        }
      )

    results = Repo.all(bucketed)

    # STEP 2: Group in Elixir
    clusters =
      results
      |> Enum.group_by(fn r -> {r.lat_bucket, r.lng_bucket} end)
      |> Enum.map(fn {{lat, lng}, votes} ->
        total = length(votes)

        # candidate breakdown
        breakdown =
          votes
          |> Enum.group_by(& &1.candidate_name)
          |> Enum.map(fn {name, v} ->
            %{
              name: name,
              count: length(v),
              color: List.first(v).candidate_color
            }
          end)

        # majority
        majority =
          Enum.max_by(breakdown, & &1.count)

        %{
          south: lat,
          north: lat + cell,
          west: lng,
          east: lng + cell,
          center_lat: lat + cell / 2,
          center_lng: lng + cell / 2,
          total_count: total,
          majority_candidate: majority.name,
          majority_color: majority.color,
          majority_count: majority.count,
          breakdown: breakdown
        }
      end)

    clusters
  end

  defp fetch_map_data(campaign_id, scope, north, south, east, west, zoom) do
    campaign = Elections.get_campaign!(scope, campaign_id)

    if zoom >= 15 do
      {"points", raw_points(campaign.id, north, south, east, west)}
    else
      {"cluster", candidate_clusters(campaign.id, north, south, east, west, zoom)}
    end
  end

  defp grid_cells(campaign_id, north, south, east, west) do
    cell = 0.02

    bucketed_query =
      from(r in Response,
        join: c in Candidate, on: c.id == r.candidate_id,
        where:
          r.campaign_id == ^campaign_id and
            not is_nil(r.latitude) and
            not is_nil(r.longitude) and
            r.latitude >= ^south and
            r.latitude <= ^north and
            r.longitude >= ^west and
            r.longitude <= ^east,
        select: %{
          lat_bucket: fragment("floor(? / ?) * ?", r.latitude, ^cell, ^cell),
          lng_bucket: fragment("floor(? / ?) * ?", r.longitude, ^cell, ^cell),
          color: c.color
        }
      )

    rows =
      from(b in subquery(bucketed_query),
        group_by: [b.lat_bucket, b.lng_bucket, b.color],
        select: %{
          lat: b.lat_bucket,
          lng: b.lng_bucket,
          color: b.color,
          votes: count()
        }
      )
      |> Repo.all()

    rows
    |> Enum.group_by(fn row -> {row.lat, row.lng} end)
    |> Enum.map(fn {{lat, lng}, cells} ->
      leader = Enum.max_by(cells, & &1.votes)
      total = Enum.reduce(cells, 0, fn x, acc -> acc + x.votes end)

      %{
        lat: lat + cell / 2,
        lng: lng + cell / 2,
        votes: total,
        color: leader.color
      }
    end)
  end

  defp booth_markers(campaign_id, north, south, east, west) do
    from(r in Response,
      join: c in Candidate, on: c.id == r.candidate_id,
      where:
        r.campaign_id == ^campaign_id and
          not is_nil(r.latitude) and
          not is_nil(r.longitude) and
          not is_nil(r.booth_name) and
          r.booth_name != "" and
          r.latitude >= ^south and
          r.latitude <= ^north and
          r.longitude >= ^west and
          r.longitude <= ^east,
      group_by: [r.booth_name, c.color],
      select: %{
        booth_name: r.booth_name,
        lat: avg(r.latitude),
        lng: avg(r.longitude),
        color: c.color,
        votes: count(r.id)
      }
    )
    |> Repo.all()
    |> Enum.group_by(& &1.booth_name)
    |> Enum.map(fn {booth_name, stats} ->
      leader = Enum.max_by(stats, & &1.votes)
      total = Enum.reduce(stats, 0, fn x, acc -> acc + x.votes end)

      %{
        booth_name: booth_name,
        lat: leader.lat,
        lng: leader.lng,
        color: leader.color,
        votes: total
      }
    end)
  end

  defp raw_points(campaign_id, north, south, east, west) do
    from(r in Response,
      join: c in Candidate, on: c.id == r.candidate_id,
      where:
        r.campaign_id == ^campaign_id and
          not is_nil(r.latitude) and
          not is_nil(r.longitude) and
          r.latitude >= ^south and
          r.latitude <= ^north and
          r.longitude >= ^west and
          r.longitude <= ^east,
      order_by: [desc: r.inserted_at],
      limit: ^@high_zoom_point_limit,
      select: %{
        lat: r.latitude,
        lng: r.longitude,
        candidate_id: r.candidate_id,
        candidate_name: c.candidate_name,
        party_full_name: c.party_full_name,
        color: c.color
      }
    )
    |> Repo.all()
  end

  defp parse_float(value) when is_binary(value), do: String.to_float(value)
  defp parse_float(value) when is_float(value), do: value
  defp parse_float(value) when is_integer(value), do: value * 1.0

  defp parse_int(value) when is_binary(value), do: String.to_integer(value)
  defp parse_int(value) when is_integer(value), do: value

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 p-4 md:p-6">
      <div class="mx-auto max-w-7xl space-y-6">
        <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 class="text-2xl font-bold text-gray-900"><%= @campaign.name %></h1>
            <p class="text-sm text-gray-600">Live TV-style campaign dashboard</p>
          </div>

          <div class="rounded-xl bg-white px-4 py-3 shadow">
            <div class="text-sm text-gray-500">Total Votes</div>
            <div class="text-3xl font-bold text-blue-600"><%= @total_votes %></div>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
          <div class="rounded-2xl bg-white p-5 shadow lg:col-span-2">
            <h2 class="mb-4 text-lg font-semibold">Top Candidate</h2>

            <%= if @top_candidate do %>
              <div class="flex items-center justify-between rounded-xl border border-green-200 bg-green-50 p-4">
                <div>
                  <div class="text-sm text-gray-500">Leading Candidate</div>
                  <div class="text-2xl font-bold text-green-700"><%= @top_candidate.candidate_name %></div>
                  <div class="text-sm text-gray-600"><%= @top_candidate.party_full_name %></div>
                </div>

                <div class="text-right">
                  <div class="text-sm text-gray-500">Votes</div>
                  <div class="text-3xl font-bold text-green-700"><%= @top_candidate.votes %></div>
                </div>
              </div>
            <% else %>
              <p class="text-gray-500">No votes yet.</p>
            <% end %>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow">
            <h2 class="mb-4 text-lg font-semibold">Gender Split</h2>
            <div id="gender-donut-chart" phx-hook="GenderDonutChart" data-stats={Jason.encode!(@gender_stats)} phx-update="ignore" class="w-full"></div>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <div class="rounded-2xl bg-white p-5 shadow">
            <h2 class="mb-4 text-lg font-semibold">Live Candidate Ranking</h2>
            <div id="candidate-bar-chart" phx-hook="CandidateBarChart" data-stats={Jason.encode!(@candidate_stats)} phx-update="ignore" class="w-full"></div>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow">
            <h2 class="mb-4 text-lg font-semibold">Age Group Split</h2>
            <div id="age-donut-chart" phx-hook="AgeDonutChart" data-stats={Jason.encode!(@age_stats)} phx-update="ignore" class="w-full"></div>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <div class="rounded-2xl bg-white p-5 shadow">
            <h2 class="mb-4 text-lg font-semibold">Party Vote Share</h2>
            <div id="party-donut-chart" phx-hook="PartyDonutChart" data-stats={Jason.encode!(@party_stats)} phx-update="ignore" class="w-full"></div>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow">
            <h2 class="mb-4 text-lg font-semibold">Vote Trend</h2>
            <div id="trend-line-chart" phx-hook="TrendLineChart" data-stats={Jason.encode!(@trend_stats)} phx-update="ignore" class="w-full"></div>
          </div>
        </div>

        <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <div class="rounded-2xl bg-white p-5 shadow">
            <h2 class="mb-4 text-lg font-semibold">Booth Turnout</h2>
            <div id="booth-turnout-chart" phx-hook="BoothTurnoutChart" data-stats={Jason.encode!(@booth_turnout_stats || [])} phx-update="ignore" class="w-full"></div>
          </div>

          <div class="rounded-2xl bg-white p-5 shadow">
            <h2 class="mb-4 text-lg font-semibold">Booth Leaders</h2>
            <div id="booth-leader-chart" phx-hook="BoothLeaderChart" data-stats={Jason.encode!(@booth_leaders || [])} phx-update="ignore" class="w-full"></div>
          </div>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow">
          <h2 class="mb-4 text-lg font-semibold">Top Booth Summary</h2>

          <%= if Enum.empty?(@top_booths) do %>
            <p class="text-sm text-gray-500">No booth-wise data available yet.</p>
          <% else %>
            <div class="overflow-auto rounded-xl border">
              <table class="min-w-full text-sm">
                <thead class="bg-gray-100">
                  <tr>
                    <th class="px-4 py-3 text-left">Booth</th>
                    <th class="px-4 py-3 text-left">Leader</th>
                    <th class="px-4 py-3 text-left">Votes</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for booth <- @top_booths do %>
                    <% leader = Enum.find(@booth_leaders, fn l -> l.booth_name == booth.booth_name end) %>
                    <tr class="border-t">
                      <td class="px-4 py-3 font-medium"><%= booth.booth_name %></td>
                      <td class="px-4 py-3"><%= leader && leader.candidate_name %></td>
                      <td class="px-4 py-3"><%= booth.votes %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>

        <div class="rounded-2xl bg-white p-5 shadow">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold">Adaptive Election Map</h2>
            <span class="text-sm text-gray-500">
  Zoom out: candidate clusters • Zoom in: individual votes
</span>
          </div>

          <p class="mb-4 text-sm text-gray-500">
  The map loads only visible area data. At lower zoom it shows candidate-wise clusters, and at higher zoom it shows individual vote points.
</p>

          <div
            id="vote-heat-map"
            phx-hook="VoteHeatMap"
            data-mode={@map_mode}
            data-points={Jason.encode!(@map_payload || [])}
            phx-update="ignore"
            class="h-[420px] md:h-[500px] w-full rounded-xl border"
          >
          </div>
        </div>
      </div>
    </div>
    """
  end
end