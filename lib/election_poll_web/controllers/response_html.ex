defmodule ElectionPollWeb.ResponseHTML do
  use ElectionPollWeb, :html

  embed_templates "response_html/*"

  def format_dt(nil), do: "-"

  def format_dt(%DateTime{} = dt),
    do: Calendar.strftime(dt, "%d-%m-%Y %I:%M:%S %p")

  def format_dt(%NaiveDateTime{} = dt),
    do: Calendar.strftime(dt, "%d-%m-%Y %I:%M:%S %p")

  def format_dt(value), do: to_string(value)

  def export_csv_path(filters) do
    params =
      %{
        campaign_id: filters.campaign_id,
        constituency_id: filters.constituency_id,
        booth_name: filters.booth_name,
        party: filters.party,
        age_group: filters.age_group,
        gender: filters.gender
      }
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == "" end)
      |> Enum.into(%{})

    "/responses/export?" <> URI.encode_query(params)
  end
end