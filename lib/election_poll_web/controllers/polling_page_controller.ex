defmodule ElectionPollWeb.PollingPageController do
  use ElectionPollWeb, :controller
  alias ElectionPoll.Elections.Campaign
  alias ElectionPoll.Elections.Candidate
  alias ElectionPoll.Repo
  alias ElectionPoll.Elections
  alias ElectionPoll.Polling

  def show(conn, %{"slug" => slug}) do
    campaign = Elections.get_campaign_by_slug(slug)

    case campaign do
      nil ->
        conn
        |> put_flash(:error, "Campaign not found.")
        |> redirect(to: ~p"/")

      campaign ->
        candidates = Elections.list_active_candidates_by_constituency(campaign.constituency_id)

        render(conn, :show,
          campaign: campaign,
          candidates: candidates
        )
    end
  end

  def submit(conn, %{"slug" => slug, "response" => response_params}) do
    campaign = Elections.get_campaign_by_slug(slug)

    case campaign do
      nil ->
        conn
        |> put_flash(:error, "Campaign not found.")
        |> redirect(to: ~p"/")

      campaign ->
        case Polling.create_public_response(campaign, response_params) do
          {:ok, _response} ->
            conn
            |> put_flash(:info, "Polling submitted successfully.")
            |> redirect(to: ~p"/c/#{campaign.slug}")

          {:error, changeset, candidates} ->
            render(conn, :show,
              campaign: campaign,
              candidates: candidates,
              changeset: changeset
            )
        end
    end
  end
end