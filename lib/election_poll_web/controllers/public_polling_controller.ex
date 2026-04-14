defmodule ElectionPollWeb.PublicPollingController do
  use ElectionPollWeb, :controller

  alias ElectionPoll.Elections
  alias ElectionPoll.Polling

  def show(conn, %{"slug" => slug}) do
    campaign = Elections.get_active_campaign_by_slug(slug)

    if campaign do
      candidates = Elections.list_active_candidates_by_constituency(campaign.constituency_id)
      IO.inspect(campaign, label: "CAMPAIGN")
      IO.inspect(candidates, label: "CANDIDATES")  
      render(conn, :show,
        campaign: campaign,
        candidates: candidates,
        error_message: nil
      )
    else
      conn
      |> put_flash(:error, "Campaign not found or inactive.")
      |> redirect(to: "/")
    end
  end

  def submit(conn, %{"slug" => slug, "response" => response_params}) do
    campaign = Elections.get_active_campaign_by_slug(slug)

    cond do
      is_nil(campaign) ->
        conn
        |> put_flash(:error, "Campaign not found or inactive.")
        |> redirect(to: "/")

      true ->
        candidates = Elections.list_active_candidates_by_constituency(campaign.constituency_id)

        case build_and_save_response(response_params, campaign, candidates) do
          {:ok, _response} ->
            conn
            |> put_flash(:info, "Polling submitted successfully.")
            |> redirect(to: ~p"/c/#{slug}/success")

          {:error, message} ->
            render(conn, :show,
              campaign: campaign,
              candidates: candidates,
              error_message: message
            )
        end
    end
  end

  def success(conn, %{"slug" => slug}) do
    campaign = Elections.get_active_campaign_by_slug(slug)
    render(conn, :success, campaign: campaign)
  end

  defp build_and_save_response(params, campaign, candidates) do
    candidate_id = params["candidate_id"]

    valid_candidate =
      Enum.any?(candidates, fn candidate ->
        to_string(candidate.id) == to_string(candidate_id)
      end)

    cond do
      is_nil(params["gender"]) or params["gender"] == "" ->
        {:error, "Please select gender."}

      is_nil(params["age_group"]) or params["age_group"] == "" ->
        {:error, "Please select age group."}

      is_nil(candidate_id) or candidate_id == "" ->
        {:error, "Please select a candidate."}

      is_nil(params["latitude"]) or params["latitude"] == "" ->
        {:error, "Location is required."}

      is_nil(params["longitude"]) or params["longitude"] == "" ->
        {:error, "Location is required."}

      not valid_candidate ->
        {:error, "Invalid candidate selection."}

      true ->
        with {:ok, selfie_path} <- save_selfie(params["selfie"]),
             attrs <- %{
               "gender" => params["gender"],
               "age_group" => params["age_group"],
               "selfie_path" => selfie_path,
               "latitude" => params["latitude"],
               "longitude" => params["longitude"],
               "submitted_at" => DateTime.utc_now() |> DateTime.truncate(:second),
               "campaign_id" => campaign.id,
               "constituency_id" => campaign.constituency_id,
               "candidate_id" => candidate_id
             },
             {:ok, response} <- Polling.create_response(attrs) do
          {:ok, response}
        else
          {:error, %Ecto.Changeset{}} ->
            {:error, "Please fill all required fields correctly."}

          {:error, message} when is_binary(message) ->
            {:error, message}

          _ ->
            {:error, "Unable to submit polling response."}
        end
    end
  end

  defp save_selfie(nil), do: {:error, "Selfie is required."}

  defp save_selfie(%Plug.Upload{filename: filename, path: path}) do
    ext = Path.extname(filename)
    unique_name = "#{System.system_time(:millisecond)}#{ext}"
    upload_dir = Path.join([:code.priv_dir(:election_poll), "static", "uploads", "selfies"])
    File.mkdir_p!(upload_dir)

    dest = Path.join(upload_dir, unique_name)

    case File.cp(path, dest) do
      :ok -> {:ok, "/uploads/selfies/#{unique_name}"}
      {:error, _} -> {:error, "Unable to save selfie."}
    end
  end

  defp save_selfie(_), do: {:error, "Invalid selfie upload."}
end