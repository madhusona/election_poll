defmodule ElectionPollWeb.ResponseController do
  use ElectionPollWeb, :controller

  import Ecto.Query

  alias ElectionPoll.Repo
  alias ElectionPoll.Polling.Response
  alias ElectionPoll.Elections.{Campaign, Candidate, Constituency}
  alias ElectionPoll.Accounts.User

  def index(conn, params) do
    scope = conn.assigns.current_scope
    current_user = scope.user
    user_id = current_user.id
    user_role = normalize_role(current_user.role)

    page =
      params
      |> Map.get("page", "1")
      |> parse_int(1)
      |> max(1)

    page_size =
      params
      |> Map.get("page_size", "50")
      |> parse_int(50)
      |> normalize_page_size()

    filters = %{
      constituency_id: blank_to_nil(params["constituency_id"]),
      booth_name: blank_to_nil(params["booth_name"]),
      party: blank_to_nil(params["party"]),
      age_group: blank_to_nil(params["age_group"]),
      gender: blank_to_nil(params["gender"]),
      campaign_id: blank_to_nil(params["campaign_id"])
    }

    base_query =
      base_response_query(user_id, user_role)

    filtered_query = apply_filters(base_query, filters)

    total_count =
      filtered_query
      |> subquery()
      |> Repo.aggregate(:count, :id)

    total_pages =
      case total_count do
        0 -> 1
        _ -> div(total_count + page_size - 1, page_size)
      end

    page = min(page, total_pages)
    offset = (page - 1) * page_size

    responses =
      filtered_query
      |> order_by([r], desc: r.submitted_at, desc: r.id)
      |> limit(^page_size)
      |> offset(^offset)
      |> Repo.all()

    constituencies =
      constituency_options(user_id, user_role)

    booths =
      booth_options(user_id, user_role)

    parties =
      party_options(user_id, user_role)

    campaigns =
      campaign_options(user_id, user_role)

    render(conn, :index,
      responses: responses,
      filters: filters,
      constituencies: constituencies,
      booths: booths,
      parties: parties,
      campaigns: campaigns,
      page: page,
      page_size: page_size,
      total_count: total_count,
      total_pages: total_pages,
      user_role: user_role
    )
  end

  def show(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    current_user = scope.user
    user_id = current_user.id
    user_role = normalize_role(current_user.role)

    response =
      detailed_response_query(user_id, user_role, id)
      |> Repo.one()

    if is_nil(response) do
      conn
      |> put_flash(:error, "Response not found or access denied.")
      |> redirect(to: ~p"/responses")
    else
      render(conn, :show,
        response: response,
        user_role: user_role,
        map_url: map_url(response.latitude, response.longitude)
      )
    end
  end

  def export_csv(conn, params) do
    scope = conn.assigns.current_scope
    current_user = scope.user
    user_id = current_user.id
    user_role = normalize_role(current_user.role)

    filters = %{
      constituency_id: blank_to_nil(params["constituency_id"]),
      booth_name: blank_to_nil(params["booth_name"]),
      party: blank_to_nil(params["party"]),
      age_group: blank_to_nil(params["age_group"]),
      gender: blank_to_nil(params["gender"]),
      campaign_id: blank_to_nil(params["campaign_id"])
    }

    rows =
      base_response_query(user_id, user_role)
      |> apply_filters(filters)
      |> order_by([r], desc: r.submitted_at, desc: r.id)
      |> Repo.all()

    csv_data =
      [
        [
          "ID",
          "Submitted At",
          "Campaign",
          "Constituency",
          "Booth",
          "Candidate",
          "Party",
          "Gender",
          "Age Group",
          "Latitude",
          "Longitude",
          "Device Fingerprint",
          "Selfie Path"
        ]
        | Enum.map(rows, fn row ->
            [
              row.id,
              format_csv_value(row.submitted_at),
              row.campaign_name,
              row.constituency_name,
              row.booth_name,
              row.candidate_name,
              row.party_full_name,
              row.gender,
              row.age_group,
              row.latitude,
              row.longitude,
              row.device_fingerprint,
              row.selfie_path
            ]
          end)
      ]
      |> Enum.map(&csv_line/1)
      |> Enum.join("")

    filename = "responses_export_#{Date.utc_today()}.csv"

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
    |> send_resp(200, csv_data)
  end

  defp base_response_query(user_id, user_role) do
    from r in Response,
      join: cam in Campaign, on: cam.id == r.campaign_id,
      join: c in Candidate, on: c.id == r.candidate_id,
      join: con in Constituency, on: con.id == r.constituency_id,
      where: ^access_filter(user_role, user_id),
      select: %{
        id: r.id,
        submitted_at: r.submitted_at,
        voted_at: r.voted_at,
        gender: r.gender,
        age_group: r.age_group,
        booth_name: r.booth_name,
        booth_id: r.booth_id,
        latitude: r.latitude,
        longitude: r.longitude,
        selfie_path: r.selfie_path,
        device_fingerprint: r.device_fingerprint,
        constituency_name: con.name,
        constituency_id: con.id,
        candidate_id: c.id,
        candidate_name: c.candidate_name,
        party_full_name: c.party_full_name,
        campaign_id: cam.id,
        campaign_name: cam.name
      }
  end

  defp detailed_response_query(user_id, user_role, id) do
    id = parse_int(id, 0)

    from r in Response,
      join: cam in Campaign, on: cam.id == r.campaign_id,
      join: c in Candidate, on: c.id == r.candidate_id,
      join: con in Constituency, on: con.id == r.constituency_id,
      where: r.id == ^id,
      where: ^access_filter(user_role, user_id),
      select: %{
        id: r.id,
        voter_name: r.voter_name,
        mobile: r.mobile,
        secret_code: r.secret_code,
        submitted_at: r.submitted_at,
        voted_at: r.voted_at,
        gender: r.gender,
        age_group: r.age_group,
        booth_name: r.booth_name,
        booth_id: r.booth_id,
        latitude: r.latitude,
        longitude: r.longitude,
        selfie_path: r.selfie_path,
        device_fingerprint: r.device_fingerprint,
        constituency_name: con.name,
        constituency_id: con.id,
        candidate_id: c.id,
        candidate_name: c.candidate_name,
        party_full_name: c.party_full_name,
        campaign_id: cam.id,
        campaign_name: cam.name
      }
  end

  defp access_filter("admin", _user_id), do: dynamic([r, cam, c, con], cam.user_id == r.user_id or not is_nil(cam.id))

  defp access_filter("subadmin", user_id),
    do: dynamic([r, cam, c, con], cam.assigned_user_id == ^user_id)

  defp access_filter(_, user_id),
    do: dynamic([r, cam, c, con], cam.user_id == ^user_id)

  defp constituency_options(user_id, "admin") do
    from(con in Constituency,
      join: cam in Campaign, on: cam.constituency_id == con.id,
      distinct: con.id,
      order_by: con.name,
      select: %{id: con.id, name: con.name}
    )
    |> Repo.all()
  end

  defp constituency_options(user_id, "subadmin") do
    from(con in Constituency,
      join: cam in Campaign, on: cam.constituency_id == con.id,
      where: cam.assigned_user_id == ^user_id,
      distinct: con.id,
      order_by: con.name,
      select: %{id: con.id, name: con.name}
    )
    |> Repo.all()
  end

  defp constituency_options(user_id, _) do
    from(con in Constituency,
      join: cam in Campaign, on: cam.constituency_id == con.id,
      where: cam.user_id == ^user_id,
      distinct: con.id,
      order_by: con.name,
      select: %{id: con.id, name: con.name}
    )
    |> Repo.all()
  end

  defp booth_options(user_id, "admin") do
    from(r in Response,
      where: not is_nil(r.booth_name) and r.booth_name != "",
      distinct: r.booth_name,
      order_by: r.booth_name,
      select: r.booth_name
    )
    |> Repo.all()
  end

  defp booth_options(user_id, "subadmin") do
    from(r in Response,
      join: cam in Campaign, on: cam.id == r.campaign_id,
      where:
        cam.assigned_user_id == ^user_id and
          not is_nil(r.booth_name) and
          r.booth_name != "",
      distinct: r.booth_name,
      order_by: r.booth_name,
      select: r.booth_name
    )
    |> Repo.all()
  end

  defp booth_options(user_id, _) do
    from(r in Response,
      join: cam in Campaign, on: cam.id == r.campaign_id,
      where:
        cam.user_id == ^user_id and
          not is_nil(r.booth_name) and
          r.booth_name != "",
      distinct: r.booth_name,
      order_by: r.booth_name,
      select: r.booth_name
    )
    |> Repo.all()
  end

  defp party_options(user_id, "admin") do
    from(c in Candidate,
      where: not is_nil(c.party_full_name) and c.party_full_name != "",
      distinct: c.party_full_name,
      order_by: c.party_full_name,
      select: c.party_full_name
    )
    |> Repo.all()
  end

  defp party_options(user_id, "subadmin") do
    from(c in Candidate,
      join: cam in Campaign, on: cam.id == c.campaign_id,
      where:
        cam.assigned_user_id == ^user_id and
          not is_nil(c.party_full_name) and
          c.party_full_name != "",
      distinct: c.party_full_name,
      order_by: c.party_full_name,
      select: c.party_full_name
    )
    |> Repo.all()
  end

  defp party_options(user_id, _) do
    from(c in Candidate,
      join: cam in Campaign, on: cam.id == c.campaign_id,
      where:
        cam.user_id == ^user_id and
          not is_nil(c.party_full_name) and
          c.party_full_name != "",
      distinct: c.party_full_name,
      order_by: c.party_full_name,
      select: c.party_full_name
    )
    |> Repo.all()
  end

  defp campaign_options(user_id, "admin") do
    from(cam in Campaign,
      order_by: cam.name,
      select: %{id: cam.id, name: cam.name}
    )
    |> Repo.all()
  end

  defp campaign_options(user_id, "subadmin") do
    from(cam in Campaign,
      where: cam.assigned_user_id == ^user_id,
      order_by: cam.name,
      select: %{id: cam.id, name: cam.name}
    )
    |> Repo.all()
  end

  defp campaign_options(user_id, _) do
    from(cam in Campaign,
      where: cam.user_id == ^user_id,
      order_by: cam.name,
      select: %{id: cam.id, name: cam.name}
    )
    |> Repo.all()
  end

  defp apply_filters(query, filters) do
    query
    |> maybe_filter_campaign(filters.campaign_id)
    |> maybe_filter_constituency(filters.constituency_id)
    |> maybe_filter_booth(filters.booth_name)
    |> maybe_filter_party(filters.party)
    |> maybe_filter_age(filters.age_group)
    |> maybe_filter_gender(filters.gender)
  end

  defp maybe_filter_campaign(query, nil), do: query
  defp maybe_filter_campaign(query, campaign_id) do
    where(query, [_r, cam, _c, _con], cam.id == ^parse_int(campaign_id, 0))
  end

  defp maybe_filter_constituency(query, nil), do: query
  defp maybe_filter_constituency(query, constituency_id) do
    where(query, [r, _cam, _c, _con], r.constituency_id == ^parse_int(constituency_id, 0))
  end

  defp maybe_filter_booth(query, nil), do: query
  defp maybe_filter_booth(query, booth_name) do
    where(query, [r, _cam, _c, _con], r.booth_name == ^booth_name)
  end

  defp maybe_filter_party(query, nil), do: query
  defp maybe_filter_party(query, party) do
    where(query, [_r, _cam, c, _con], c.party_full_name == ^party)
  end

  defp maybe_filter_age(query, nil), do: query
  defp maybe_filter_age(query, age_group) do
    where(query, [r, _cam, _c, _con], r.age_group == ^age_group)
  end

  defp maybe_filter_gender(query, nil), do: query
  defp maybe_filter_gender(query, gender) do
    where(query, [r, _cam, _c, _con], r.gender == ^gender)
  end

  defp maybe_filter_campaign(query, nil), do: query
  defp maybe_filter_campaign(query, campaign_id) do
    where(query, [r], r.campaign_id == ^parse_int(campaign_id, 0))
  end

  defp maybe_filter_constituency(query, nil), do: query
  defp maybe_filter_constituency(query, constituency_id) do
    where(query, [r], r.constituency_id == ^parse_int(constituency_id, 0))
  end

  defp maybe_filter_booth(query, nil), do: query
  defp maybe_filter_booth(query, booth_name) do
    where(query, [r], r.booth_name == ^booth_name)
  end

  defp maybe_filter_party(query, nil), do: query
  defp maybe_filter_party(query, party) do
    where(query, [_r], _r.party_full_name == ^party)
  end

  defp maybe_filter_age(query, nil), do: query
  defp maybe_filter_age(query, age_group) do
    where(query, [r], r.age_group == ^age_group)
  end

  defp maybe_filter_gender(query, nil), do: query
  defp maybe_filter_gender(query, gender) do
    where(query, [r], r.gender == ^gender)
  end

  defp map_url(nil, nil), do: nil
  defp map_url(lat, lng) do
    "https://www.openstreetmap.org/?mlat=#{lat}&mlon=#{lng}#map=17/#{lat}/#{lng}"
  end

  defp csv_line(fields) do
    fields
    |> Enum.map(&escape_csv_field/1)
    |> Enum.join(",")
    |> Kernel.<>("\n")
  end

  defp escape_csv_field(nil), do: "\"\""

  defp escape_csv_field(value) do
    value =
      case value do
        %NaiveDateTime{} -> NaiveDateTime.to_string(value)
        %DateTime{} -> DateTime.to_string(value)
        _ -> to_string(value)
      end

    "\"" <> String.replace(value, "\"", "\"\"") <> "\""
  end

  defp format_csv_value(nil), do: ""
  defp format_csv_value(%NaiveDateTime{} = dt), do: NaiveDateTime.to_string(dt)
  defp format_csv_value(%DateTime{} = dt), do: DateTime.to_string(dt)
  defp format_csv_value(value), do: to_string(value)

  defp parse_int(nil, default), do: default
  defp parse_int(value, _default) when is_integer(value), do: value
  defp parse_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> default
    end
  end

  defp normalize_page_size(size) when size in [50, 100], do: size
  defp normalize_page_size(_), do: 50

  defp blank_to_nil(nil), do: nil
  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  defp normalize_role(nil), do: "user"
  defp normalize_role(role) when is_atom(role), do: Atom.to_string(role)
  defp normalize_role(role) when is_binary(role), do: role
  def format_dt(nil), do: "-"
  def format_dt(%DateTime{} = dt), do: Calendar.strftime(dt, "%d-%m-%Y %I:%M:%S %p")
  def format_dt(%NaiveDateTime{} = dt), do: Calendar.strftime(dt, "%d-%m-%Y %I:%M:%S %p")
  def format_dt(value), do: to_string(value)
end