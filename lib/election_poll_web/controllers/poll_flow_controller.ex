defmodule ElectionPollWeb.PollFlowController do
  use ElectionPollWeb, :controller

  alias ElectionPoll.Elections
  alias ElectionPoll.Polling

  def constituency(conn, %{"slug" => slug}) do
    campaign = Elections.get_active_campaign_with_constituency_by_slug(slug)

    if campaign do
      constituencies = Elections.list_active_constituencies_by_user(campaign.user_id)

      render(conn, :constituency,
        campaign: campaign,
        constituencies: constituencies
      )
    else
      conn
      |> put_flash(:error, "Campaign not found or inactive.")
      |> redirect(to: "/")
    end
  end

  def booth(conn, %{"slug" => slug, "constituency_id" => constituency_id}) do
    campaign = Elections.get_active_campaign_with_constituency_by_slug(slug)

    cond do
        is_nil(campaign) ->
        conn
        |> put_flash(:error, "Campaign not found or inactive.")
        |> redirect(to: "/")

        true ->
        constituency = Elections.get_constituency_by_user!(campaign.user_id, constituency_id)
        booths = Elections.list_active_booths_by_constituency(constituency.id)

        render(conn, :booth,
            campaign: campaign,
            constituency: constituency,
            booths: booths
        )
    end
  end

  def demographic(conn, %{
        "slug" => slug,
        "constituency_id" => constituency_id,
        "booth_id" => booth_id,
        "booth_name" => booth_name
        }) do
    campaign = Elections.get_active_campaign_with_constituency_by_slug(slug)

    cond do
        is_nil(campaign) ->
        conn
        |> put_flash(:error, "Campaign not found or inactive.")
        |> redirect(to: "/")

        is_nil(booth_name) or booth_name == "" ->
        conn
        |> put_flash(:error, "Please select a booth.")
        |> redirect(to: ~p"/poll/#{slug}/booth?constituency_id=#{constituency_id}")

        true ->
        constituency = Elections.get_constituency_by_user!(campaign.user_id, constituency_id)

        render(conn, :demographic,
            campaign: campaign,
            constituency: constituency,
            booth_id: booth_id,
            booth_name: booth_name
        )
    end
    end

  def permission_denied(conn, params) do
    slug = params["slug"]
    constituency_id = params["constituency_id"]
    booth_id = params["booth_id"]
    booth_name = params["booth_name"]
    gender = params["gender"]
    age_group = params["age_group"]

    campaign = Elections.get_active_campaign_with_constituency_by_slug(slug)

    cond do
      is_nil(campaign) ->
        conn
        |> put_flash(:error, "Campaign not found or inactive.")
        |> redirect(to: "/")

      true ->
        constituency = Elections.get_constituency_by_user!(campaign.user_id, constituency_id)

        render(conn, :permission_denied,
          campaign: campaign,
          constituency: constituency,
          booth_id: booth_id,
          booth_name: booth_name,
          gender: gender,
          age_group: age_group
        )
    end
  end

  def vote(conn, params) do
    slug = params["slug"]
    constituency_id = params["constituency_id"]
    booth_id = params["booth_id"]
    booth_name = params["booth_name"]
    gender = params["gender"]
    age_group = params["age_group"]
    latitude = params["latitude"]
    longitude = params["longitude"]
    camera_verified = params["camera_verified"]
    location_verified = params["location_verified"]

    campaign = Elections.get_active_campaign_with_constituency_by_slug(slug)

    cond do
      is_nil(campaign) ->
        conn
        |> put_flash(:error, "Campaign not found or inactive.")
        |> redirect(to: "/")

      is_nil(booth_id) or booth_id == "" ->
        conn
        |> put_flash(:error, "Please select a booth.")
        |> redirect(to: ~p"/poll/#{slug}/booth?constituency_id=#{constituency_id}")

      is_nil(booth_name) or booth_name == "" ->
        conn
        |> put_flash(:error, "Please select a booth.")
        |> redirect(to: ~p"/poll/#{slug}/booth?constituency_id=#{constituency_id}")

      gender not in ["Male", "Female", "Other"] ->
        conn
        |> put_flash(:error, "Invalid gender selection.")
        |> redirect(
          to:
            ~p"/poll/#{slug}/demographic?constituency_id=#{constituency_id}&booth_id=#{booth_id}&booth_name=#{booth_name}"
        )

      age_group not in ["18-20", "20-40", "40-60", "60+"] ->
        conn
        |> put_flash(:error, "Invalid age group selection.")
        |> redirect(
          to:
            ~p"/poll/#{slug}/demographic?constituency_id=#{constituency_id}&booth_id=#{booth_id}&booth_name=#{booth_name}"
        )

      camera_verified != "true" or location_verified != "true" ->
        conn
        |> put_flash(:error, "Camera and location permissions are required.")
        |> redirect(
          to:
            ~p"/poll/#{slug}/access?constituency_id=#{constituency_id}&booth_id=#{booth_id}&booth_name=#{booth_name}&gender=#{gender}&age_group=#{age_group}"
        )

      true ->
        total_votes = Polling.count_votes(campaign.id, %{})
        constituency = Elections.get_constituency_by_user!(campaign.user_id, constituency_id)
        candidates = Elections.list_active_candidates_by_constituency(constituency.id)

        render(conn, :vote,
          campaign: campaign,
          total_votes: total_votes,
          constituency: constituency,
          candidates: candidates,
          booth_id: booth_id,
          booth_name: booth_name,
          gender: gender,
          age_group: age_group,
          latitude: latitude,
          longitude: longitude,
          error_message: nil
        )
    end
  end
  def submit(conn, %{"slug" => slug, "response" => response_params}) do
    campaign = Elections.get_active_campaign_with_constituency_by_slug(slug)

    cond do
      is_nil(campaign) ->
        conn
        |> put_flash(:error, "Campaign not found or inactive.")
        |> redirect(to: "/")

      true ->
        constituency =
          Elections.get_constituency_by_user!(campaign.user_id, response_params["constituency_id"])

        candidates = Elections.list_active_candidates_by_constituency(constituency.id)

        case build_and_save_response(response_params, campaign, constituency, candidates) do
          {:ok, response} ->
            ElectionPollWeb.Endpoint.broadcast(
                "campaign:#{response.campaign_id}",
                "new_vote",
                %{
                    campaign_id: response.campaign_id,
                    candidate_id: response.candidate_id,
                    constituency_id: response.constituency_id
                }
                )
            conn
            |> put_flash(:info, "Polling submitted successfully.")
            |> redirect(
              to:
                ~p"/poll/#{slug}/success?constituency_id=#{constituency.id}&gender=#{response_params["gender"]}&age_group=#{response_params["age_group"]}"
            )

          {:error, message} ->
            render(conn, :vote,
                campaign: campaign,
                constituency: constituency,
                candidates: candidates,
                booth_id: response_params["booth_id"],
                booth_name: response_params["booth_name"],
                gender: response_params["gender"],
                age_group: response_params["age_group"],
                latitude: response_params["latitude"],
                longitude: response_params["longitude"],
                error_message: message
            )
        end
    end
  end

  def success(conn, %{"slug" => slug} = params) do
    campaign = Elections.get_active_campaign_with_constituency_by_slug(slug)

    constituency =
      case params["constituency_id"] do
        nil -> nil
        constituency_id when not is_nil(campaign) ->
          Elections.get_constituency_by_user!(campaign.user_id, constituency_id)
      end

    render(conn, :success,
      campaign: campaign,
      constituency: constituency,
      gender: params["gender"],
      age_group: params["age_group"]
    )
  end

  defp build_and_save_response(params, campaign, constituency, candidates) do
    candidate_id = params["candidate_id"]
    booth_id = params["booth_id"]

    valid_candidate =
        Enum.any?(candidates, fn candidate ->
        to_string(candidate.id) == to_string(candidate_id)
        end)

    valid_booth =
    try do
        case booth_id do
        nil ->
            false

        "" ->
            false

        _ ->
            booth = Elections.get_booth_by_constituency!(constituency.id, booth_id)
            not is_nil(booth)
        end
    rescue
        _ -> false
    end

    cond do
        params["gender"] not in ["Male", "Female", "Other"] ->
        {:error, "Please select gender."}

        params["age_group"] not in ["18-20", "20-40", "40-60", "60+"] ->
        {:error, "Please select age group."}

        is_nil(params["booth_name"]) or params["booth_name"] == "" ->
        {:error, "Please select a booth."}

        is_nil(params["voted_at"]) or params["voted_at"] == "" ->
          {:error, "Vote timestamp is required."}

        is_nil(params["device_fingerprint"]) or params["device_fingerprint"] == "" ->
          {:error, "Device fingerprint is required."}

        is_nil(params["booth_id"]) or params["booth_id"] == "" ->
        {:error, "Please select a booth."}

        not valid_booth ->
        {:error, "Invalid booth selection."}

        is_nil(candidate_id) or candidate_id == "" ->
        {:error, "Please select a candidate."}

        not valid_candidate ->
        {:error, "Invalid candidate selection."}

        is_nil(params["latitude"]) or params["latitude"] == "" ->
        {:error, "Location is required."}

        is_nil(params["longitude"]) or params["longitude"] == "" ->
        {:error, "Location is required."}

        true ->
        with {:ok, selfie_path} <- save_selfie(params["selfie"], params["selfie_base64"]),
            booth <- Elections.get_booth_by_constituency!(constituency.id, booth_id),
            attrs <- %{
                "gender" => params["gender"],
                "age_group" => params["age_group"],
                "booth_id" => booth.id,
                "booth_name" => booth.name,
                "selfie_path" => selfie_path,
                "latitude" => params["latitude"],
                "longitude" => params["longitude"],
                "submitted_at" => DateTime.utc_now() |> DateTime.truncate(:second),
                "campaign_id" => campaign.id,
                "constituency_id" => constituency.id,
                "candidate_id" => candidate_id,
                "voted_at" => params["voted_at"],
                "device_fingerprint" => params["device_fingerprint"],
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

  def submit_ajax(conn, %{"slug" => slug, "response" => response_params}) do
    campaign = Elections.get_active_campaign_with_constituency_by_slug(slug)

    cond do
      is_nil(campaign) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{ok: false, error: "Campaign not found or inactive."})

      true ->
        constituency =
          Elections.get_constituency_by_user!(campaign.user_id, response_params["constituency_id"])

        candidates = Elections.list_active_candidates_by_constituency(constituency.id)

        case build_and_save_response(response_params, campaign, constituency, candidates) do
          {:ok, response} ->
            candidate =
              Enum.find(candidates, fn c ->
                to_string(c.id) == to_string(response.candidate_id)
              end)

            ElectionPollWeb.Endpoint.broadcast(
              "campaign:#{response.campaign_id}",
              "new_vote",
              %{
                campaign_id: response.campaign_id,
                candidate_id: response.candidate_id,
                constituency_id: response.constituency_id
              }
            )

            json(conn, %{
              ok: true,
              vote_id: response.id,
              candidate_id: response.candidate_id,
              candidate_name: candidate && candidate.candidate_name,
              party_name: candidate && candidate.party_full_name,
              symbol_image: candidate && candidate.symbol_image,
              redirect_url:
                ~p"/poll/#{slug}/success?constituency_id=#{response.constituency_id}&gender=#{response.gender}&age_group=#{response.age_group}"
            })

          {:error, message} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{ok: false, error: message})
        end
    end
  end

  def access(conn, %{
        "slug" => slug,
        "constituency_id" => constituency_id,
        "booth_id" => booth_id,
        "booth_name" => booth_name,
        "gender" => gender,
        "age_group" => age_group
        }) do
    campaign = Elections.get_active_campaign_with_constituency_by_slug(slug)

    cond do
        is_nil(campaign) ->
        conn
        |> put_flash(:error, "Campaign not found or inactive.")
        |> redirect(to: "/")

        is_nil(booth_id) or booth_id == "" ->
        conn
        |> put_flash(:error, "Please select a booth.")
        |> redirect(to: ~p"/poll/#{slug}/booth?constituency_id=#{constituency_id}")

        
        is_nil(booth_name) or booth_name == "" ->
        conn
        |> put_flash(:error, "Please select a booth.")
        |> redirect(to: ~p"/poll/#{slug}/booth?constituency_id=#{constituency_id}")

        gender not in ["Male", "Female", "Other"] ->
        conn
        |> put_flash(:error, "Invalid gender selection.")
        |> redirect(to: ~p"/poll/#{slug}")

        age_group not in ["18-20", "20-40", "40-60", "60+"] ->
        conn
        |> put_flash(:error, "Invalid age group selection.")
        |> redirect(to: ~p"/poll/#{slug}")

        true ->
        constituency = Elections.get_constituency_by_user!(campaign.user_id, constituency_id)

        render(conn, :access,
            campaign: campaign,
            constituency: constituency,
            booth_id: booth_id,
            booth_name: booth_name,
            gender: gender,
            age_group: age_group
        )
    end
    end

  defp save_selfie(nil), do: {:error, "Selfie is required."}

  defp save_selfie(upload, base64_data) do
    cond do
        is_binary(base64_data) and String.starts_with?(base64_data, "data:image/") ->
        save_base64_selfie(base64_data)

        not is_nil(upload) ->
        save_uploaded_selfie(upload)

        true ->
        {:error, "Selfie is required."}
    end
    end

    defp save_uploaded_selfie(%Plug.Upload{filename: filename, path: path}) do
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

    defp save_uploaded_selfie(_), do: {:error, "Invalid selfie upload."}

    defp save_base64_selfie(data_url) do
    with [header, encoded] <- String.split(data_url, ",", parts: 2),
        {:ok, binary} <- Base.decode64(encoded) do
        ext =
        cond do
            String.contains?(header, "image/png") -> ".png"
            String.contains?(header, "image/webp") -> ".webp"
            true -> ".jpg"
        end

        unique_name = "#{System.system_time(:millisecond)}#{ext}"
        upload_dir = Path.join([:code.priv_dir(:election_poll), "static", "uploads", "selfies"])
        File.mkdir_p!(upload_dir)

        dest = Path.join(upload_dir, unique_name)

        case File.write(dest, binary) do
        :ok -> {:ok, "/uploads/selfies/#{unique_name}"}
        {:error, _} -> {:error, "Unable to save captured selfie."}
        end
    else
        _ -> {:error, "Invalid captured selfie data."}
    end
    end

  defp save_selfie(_), do: {:error, "Invalid selfie upload."}
end