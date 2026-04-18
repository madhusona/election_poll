defmodule ElectionPollWeb.ResponseController do
  use ElectionPollWeb, :controller

  import Ecto.Query

  alias ElectionPoll.Repo
  alias ElectionPoll.Polling.Response
  alias ElectionPoll.Elections.{Campaign, Candidate, Constituency, State}
  alias ElectionPoll.Accounts.AccessControl

  def index(conn, params) do
    current_user = conn.assigns.current_scope.user
    user_role = normalize_role(current_user.role)

    permissions = AccessControl.feature_permissions(current_user)
    allowed_scope = AccessControl.allowed_scope(current_user)

    if user_role != "admin" and not permissions["can_view_responses"] do
      conn
      |> put_flash(:error, "You are not allowed to view responses.")
      |> redirect(to: ~p"/")
    else
      filters = %{
        campaign_id: blank_to_nil(params["campaign_id"]),
        constituency_id: blank_to_nil(params["constituency_id"]),
        booth_name: blank_to_nil(params["booth_name"]),
        party: blank_to_nil(params["party"]),
        age_group: blank_to_nil(params["age_group"]),
        gender: blank_to_nil(params["gender"])
      }

      page = parse_int(params["page"], 1)
      page_size = normalize_page_size(parse_int(params["page_size"], 50))
      offset = max(page - 1, 0) * page_size

      base_query =
        base_response_query(current_user, user_role, allowed_scope)
        |> apply_filters(filters)

      total_count = Repo.aggregate(base_query, :count, :id)

      responses =
        base_query
        |> order_by([r, _cam, _c, _con, _s], desc: r.submitted_at, desc: r.id)
        |> limit(^page_size)
        |> offset(^offset)
        |> Repo.all()
        |> Enum.map(&mask_response_fields(&1, permissions, user_role))

      total_pages =
        case total_count do
          0 -> 1
          count -> div(count + page_size - 1, page_size)
        end

      conn
      |> assign(:page_title, "Responses")
      |> assign(:responses, responses)
      |> assign(:filters, filters)
      |> assign(:campaigns, campaign_options(current_user, user_role, allowed_scope))
      |> assign(:constituencies, constituency_options(current_user, user_role, allowed_scope))
      |> assign(:booths, booth_options(current_user, user_role, allowed_scope))
      |> assign(:parties, party_options(current_user, user_role, allowed_scope))
      |> assign(:page, page)
      |> assign(:page_size, page_size)
      |> assign(:total_pages, total_pages)
      |> assign(:total_count, total_count)
      |> assign(:user_role, user_role)
      |> assign(:permissions, permissions)
      |> render(:index)
    end
  end

  def show(conn, %{"id" => id}) do
    current_user = conn.assigns.current_scope.user
    user_role = normalize_role(current_user.role)

    permissions = AccessControl.feature_permissions(current_user)
    allowed_scope = AccessControl.allowed_scope(current_user)

    if user_role != "admin" and not permissions["can_view_response_detail"] do
      conn
      |> put_flash(:error, "You are not allowed to view response details.")
      |> redirect(to: ~p"/responses")
    else
      response =
        detailed_response_query(current_user, user_role, allowed_scope, parse_int(id, 0))
        |> Repo.one()

      case response do
        nil ->
          raise Ecto.NoResultsError, queryable: Response

        response ->
          masked = mask_response_fields(response, permissions, user_role)

          conn
          |> assign(:page_title, "Response Details")
          |> assign(:response, masked)
          |> assign(:user_role, user_role)
          |> assign(:permissions, permissions)
          |> render(:show)
      end
    end
  end

  def export_csv(conn, params) do
    current_user = conn.assigns.current_scope.user
    user_role = normalize_role(current_user.role)

    permissions = AccessControl.feature_permissions(current_user)
    allowed_scope = AccessControl.allowed_scope(current_user)

    if user_role != "admin" and not permissions["can_export_responses"] do
      conn
      |> put_flash(:error, "You are not allowed to export responses.")
      |> redirect(to: ~p"/responses")
    else
      filters = %{
        campaign_id: blank_to_nil(params["campaign_id"]),
        constituency_id: blank_to_nil(params["constituency_id"]),
        booth_name: blank_to_nil(params["booth_name"]),
        party: blank_to_nil(params["party"]),
        age_group: blank_to_nil(params["age_group"]),
        gender: blank_to_nil(params["gender"])
      }

      rows =
        base_response_query(current_user, user_role, allowed_scope)
        |> apply_filters(filters)
        |> order_by([r, _cam, _c, _con, _s], desc: r.submitted_at, desc: r.id)
        |> Repo.all()
        |> Enum.map(&mask_response_fields(&1, permissions, user_role))

      headers = [
        "Response ID",
        "Campaign",
        "Constituency",
        "Booth",
        "Candidate",
        "Party",
        "Gender",
        "Age Group",
        "Submitted At",
        "Voted At",
        "Latitude",
        "Longitude",
        "Device Fingerprint"
      ]

      csv_rows =
        Enum.map(rows, fn row ->
          [
            row.id,
            row.campaign_name,
            row.constituency_name,
            row.booth_name,
            row.candidate_name,
            row.party_full_name,
            row.gender,
            row.age_group,
            format_csv_value(row.submitted_at),
            format_csv_value(row.voted_at),
            format_csv_value(row.latitude),
            format_csv_value(row.longitude),
            row.device_fingerprint
          ]
        end)

      csv_content =
        [headers | csv_rows]
        |> Enum.map(&csv_line/1)
        |> IO.iodata_to_binary()

      filename = "responses.csv"

      conn
      |> put_resp_content_type("text/csv")
      |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
      |> send_resp(200, csv_content)
    end
  end

  defp base_response_query(current_user, user_role, allowed_scope) do
    from r in Response,
      join: cam in Campaign, on: cam.id == r.campaign_id,
      join: c in Candidate, on: c.id == r.candidate_id,
      join: con in Constituency, on: con.id == r.constituency_id,
      join: s in State, on: s.id == con.state_id,
      where: ^response_access_filter(user_role, current_user.id, allowed_scope),
      select: %{
        id: r.id,
        submitted_at: r.submitted_at,
        voted_at: r.voted_at,
        voter_name: r.voter_name,
        mobile: r.mobile,
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
        state_id: s.id,
        state_name: s.name,
        candidate_id: c.id,
        candidate_name: c.candidate_name,
        party_full_name: c.party_full_name,
        campaign_id: cam.id,
        campaign_name: cam.name
      }
  end

  defp detailed_response_query(current_user, user_role, allowed_scope, response_id) do
    from r in Response,
      join: cam in Campaign, on: cam.id == r.campaign_id,
      join: c in Candidate, on: c.id == r.candidate_id,
      join: con in Constituency, on: con.id == r.constituency_id,
      join: s in State, on: s.id == con.state_id,
      where: r.id == ^response_id,
      where: ^response_access_filter(user_role, current_user.id, allowed_scope),
      select: %{
        id: r.id,
        submitted_at: r.submitted_at,
        voted_at: r.voted_at,
        voter_name: r.voter_name,
        mobile: r.mobile,
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
        state_id: s.id,
        state_name: s.name,
        candidate_id: c.id,
        candidate_name: c.candidate_name,
        party_full_name: c.party_full_name,
        campaign_id: cam.id,
        campaign_name: cam.name
      }
  end

  defp campaign_options(current_user, user_role, allowed_scope) do
    from(cam in Campaign,
      join: con in Constituency,
      on: con.id == cam.constituency_id,
      join: s in State,
      on: s.id == con.state_id,
      where: ^campaign_access_filter(user_role, current_user.id, allowed_scope),
      order_by: [asc: cam.name],
      select: %{id: cam.id, name: cam.name}
    )
    |> Repo.all()
  end

  defp constituency_options(current_user, user_role, allowed_scope) do
    from(con in Constituency,
      join: cam in Campaign,
      on: cam.constituency_id == con.id,
      join: s in State,
      on: s.id == con.state_id,
      where: ^campaign_access_filter(user_role, current_user.id, allowed_scope),
      distinct: con.id,
      order_by: [asc: con.name],
      select: %{id: con.id, name: con.name}
    )
    |> Repo.all()
  end

  defp booth_options(current_user, user_role, allowed_scope) do
    from(r in Response,
      join: cam in Campaign,
      on: cam.id == r.campaign_id,
      join: c in Candidate,
      on: c.id == r.candidate_id,
      join: con in Constituency,
      on: con.id == r.constituency_id,
      join: s in State,
      on: s.id == con.state_id,
      where: ^response_access_filter(user_role, current_user.id, allowed_scope),
      where: not is_nil(r.booth_name) and r.booth_name != "",
      distinct: r.booth_name,
      order_by: [asc: r.booth_name],
      select: r.booth_name
    )
    |> Repo.all()
  end

  defp party_options(current_user, user_role, allowed_scope) do
    from(r in Response,
      join: cam in Campaign,
      on: cam.id == r.campaign_id,
      join: c in Candidate,
      on: c.id == r.candidate_id,
      join: con in Constituency,
      on: con.id == r.constituency_id,
      join: s in State,
      on: s.id == con.state_id,
      where: ^response_access_filter(user_role, current_user.id, allowed_scope),
      where: not is_nil(c.party_full_name) and c.party_full_name != "",
      distinct: c.party_full_name,
      order_by: [asc: c.party_full_name],
      select: c.party_full_name
    )
    |> Repo.all()
  end

  defp campaign_access_filter("admin", _user_id, _allowed_scope) do
    dynamic([_cam, _con, _s], true)
  end

  defp campaign_access_filter("subadmin", _user_id, allowed_scope) do
    dynamic(
      [cam, con, s],
      (^Enum.empty?(allowed_scope.campaign_ids) or cam.id in ^allowed_scope.campaign_ids) and
        (^Enum.empty?(allowed_scope.state_ids) or s.id in ^allowed_scope.state_ids) and
        (^Enum.empty?(allowed_scope.constituency_ids) or con.id in ^allowed_scope.constituency_ids)
    )
  end

  defp campaign_access_filter(_role, user_id, allowed_scope) do
    dynamic(
      [cam, con, s],
      cam.user_id == ^user_id and
        (^Enum.empty?(allowed_scope.campaign_ids) or cam.id in ^allowed_scope.campaign_ids) and
        (^Enum.empty?(allowed_scope.state_ids) or s.id in ^allowed_scope.state_ids) and
        (^Enum.empty?(allowed_scope.constituency_ids) or con.id in ^allowed_scope.constituency_ids)
    )
  end

  defp response_access_filter("admin", _user_id, _allowed_scope) do
    dynamic([_r, _cam, _c, _con, _s], true)
  end

  defp response_access_filter("subadmin", _user_id, allowed_scope) do
    dynamic(
      [r, cam, _c, con, s],
      (^Enum.empty?(allowed_scope.campaign_ids) or cam.id in ^allowed_scope.campaign_ids) and
        (^Enum.empty?(allowed_scope.state_ids) or s.id in ^allowed_scope.state_ids) and
        (^Enum.empty?(allowed_scope.constituency_ids) or con.id in ^allowed_scope.constituency_ids) and
        (^Enum.empty?(allowed_scope.device_fingerprints) or
          r.device_fingerprint in ^allowed_scope.device_fingerprints)
    )
  end

  defp response_access_filter(_role, user_id, allowed_scope) do
    dynamic(
      [r, cam, _c, con, s],
      cam.user_id == ^user_id and
        (^Enum.empty?(allowed_scope.campaign_ids) or cam.id in ^allowed_scope.campaign_ids) and
        (^Enum.empty?(allowed_scope.state_ids) or s.id in ^allowed_scope.state_ids) and
        (^Enum.empty?(allowed_scope.constituency_ids) or con.id in ^allowed_scope.constituency_ids) and
        (^Enum.empty?(allowed_scope.device_fingerprints) or
          r.device_fingerprint in ^allowed_scope.device_fingerprints)
    )
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
    where(query, [_r, cam, _c, _con, _s], cam.id == ^parse_int(campaign_id, 0))
  end

  defp maybe_filter_constituency(query, nil), do: query

  defp maybe_filter_constituency(query, constituency_id) do
    where(query, [_r, _cam, _c, con, _s], con.id == ^parse_int(constituency_id, 0))
  end

  defp maybe_filter_booth(query, nil), do: query

  defp maybe_filter_booth(query, booth_name) do
    where(query, [r, _cam, _c, _con, _s], r.booth_name == ^booth_name)
  end

  defp maybe_filter_party(query, nil), do: query

  defp maybe_filter_party(query, party) do
    where(query, [_r, _cam, c, _con, _s], c.party_full_name == ^party)
  end

  defp maybe_filter_age(query, nil), do: query

  defp maybe_filter_age(query, age_group) do
    where(query, [r, _cam, _c, _con, _s], r.age_group == ^age_group)
  end

  defp maybe_filter_gender(query, nil), do: query

  defp maybe_filter_gender(query, gender) do
    where(query, [r, _cam, _c, _con, _s], r.gender == ^gender)
  end

  defp mask_response_fields(response, _permissions, "admin"), do: response

  defp mask_response_fields(response, permissions, _role) do
    response
    |> maybe_mask(:voter_name, permissions["can_view_voter_name"])
    |> maybe_mask(:mobile, permissions["can_view_mobile"])
    |> maybe_mask(:selfie_path, permissions["can_view_selfie"])
    |> maybe_mask(:device_fingerprint, permissions["can_view_device_fingerprint"])
    |> maybe_mask_location(permissions)
  end

  defp maybe_mask(map, _field, true), do: map
  defp maybe_mask(map, field, false), do: Map.put(map, field, nil)
  defp maybe_mask(map, field, nil), do: Map.put(map, field, nil)

  defp maybe_mask_location(map, permissions) do
    cond do
      permissions["can_view_location"] && permissions["can_view_exact_coordinates"] ->
        map

      permissions["can_view_location"] ->
        map
        |> Map.put(:latitude, nil)
        |> Map.put(:longitude, nil)

      true ->
        map
        |> Map.put(:latitude, nil)
        |> Map.put(:longitude, nil)
    end
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