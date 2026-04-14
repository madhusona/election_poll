defmodule ElectionPollWeb.CampaignDashboardController do
  use ElectionPollWeb, :controller
  import Ecto.Query

  alias ElectionPoll.Repo

  def index(conn, %{"id" => campaign_id} = params) do
    campaign_id = to_int!(campaign_id)

    filters = build_filters(params)
    IO.inspect(filters, label: "FILTERS")

    # ✅ Base query
    base_query =
      from r in "responses",
        where: r.campaign_id == ^campaign_id

    # ✅ Apply filters safely
    filtered_query =
      Enum.reduce(filters, base_query, fn
        {:gender, val}, q ->
          from r in q, where: r.gender == ^val

        {:age_group, val}, q ->
          from r in q, where: r.age_group == ^val

        {:constituency_id, val}, q ->
          from r in q, where: r.constituency_id == ^to_int!(val)

        {:candidate_id, val}, q ->
          from r in q, where: r.candidate_id == ^to_int!(val)

        _, q ->
          q
      end)

    # ✅ Metrics
    total_votes = Repo.aggregate(filtered_query, :count)

    # ✅ Candidate stats (JOIN for names)
    candidate_stats =
      from(r in "responses",
        join: c in "candidates",
        on: r.candidate_id == c.id,
        where: r.campaign_id == ^campaign_id,
        group_by: [c.id, c.candidate_name],
        select: %{
          candidate_id: c.id,
          name: c.candidate_name,
          count: count(r.id)
        }
      )
      |> apply_filters(filters)
      |> Repo.all()

    # ✅ Gender stats
    gender_stats =
      from(r in filtered_query,
        group_by: r.gender,
        select: %{
          gender: r.gender,
          count: count(r.id)
        }
      )
      |> Repo.all()

    # ✅ Age stats
    age_stats =
      from(r in filtered_query,
        group_by: r.age_group,
        select: %{
          age_group: r.age_group,
          count: count(r.id)
        }
      )
      |> Repo.all()

    IO.inspect(candidate_stats, label: "CANDIDATE STATS")
    constituencies =
        from(c in "constituencies",
            select: %{id: c.id, name: c.name}
        )
        |> Repo.all()

        candidates =
        from(c in "candidates",
            where: c.is_active == true,
            select: %{id: c.id, name: c.candidate_name}
        )
        |> Repo.all()

    render(conn, :index,
    total_votes: total_votes,
    candidate_stats: candidate_stats,
    gender_stats: gender_stats,
    age_stats: age_stats,
    filters: params,
    constituencies: constituencies,
    candidates: candidates
    )
  end

  # ================================
  # 🔹 FILTER BUILDER
  # ================================
  defp build_filters(params) do
    Enum.filter([
      {:gender, params["gender"]},
      {:age_group, params["age_group"]},
      {:constituency_id, params["constituency_id"]},
      {:candidate_id, params["candidate_id"]}
    ], fn {_, v} -> v not in [nil, ""] end)
  end

  # ================================
  # 🔹 APPLY FILTERS TO ANY QUERY
  # ================================
  defp apply_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:gender, val}, q ->
        from r in q, where: r.gender == ^val

      {:age_group, val}, q ->
        from r in q, where: r.age_group == ^val

      {:constituency_id, val}, q ->
        from r in q, where: r.constituency_id == ^to_int!(val)

      {:candidate_id, val}, q ->
        from r in q, where: r.candidate_id == ^to_int!(val)

      _, q ->
        q
    end)
  end

  # ================================
  # 🔹 SAFE INTEGER CONVERSION
  # ================================
  defp to_int!(val) when is_integer(val), do: val

  defp to_int!(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, ""} -> int
      _ -> raise ArgumentError, "Invalid integer value: #{inspect(val)}"
    end
  end

  defp to_int!(val),
    do: raise ArgumentError, "Unsupported type for integer conversion: #{inspect(val)}"
end