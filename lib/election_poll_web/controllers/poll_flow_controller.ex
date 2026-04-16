defmodule ElectionPollWeb.PollFlowController do
  use ElectionPollWeb, :controller

 

  alias ElectionPoll.Repo
  alias ElectionPoll.SelfieStorage
  alias ElectionPoll.Uploads
  alias ElectionPoll.Polling
  alias ElectionPoll.Elections

  def constituency(conn, %{"slug" => slug}) do
    campaign = Elections.get_active_campaign_with_constituency_by_slug(slug)

    if campaign do
      state_id = campaign.constituency && campaign.constituency.state_id

    constituencies =
      if state_id do
        Elections.list_active_constituencies_by_user_and_state(campaign.user_id, state_id)
      else
        []
      end
    constituency_ids = Enum.map(constituencies, & &1.id)
    candidate_counts = Elections.count_active_candidates_by_constituency_ids(constituency_ids)

      render(conn, :constituency,
        campaign: campaign,
        constituencies: constituencies,
        candidate_counts: candidate_counts
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

        conn =
          put_vote_entry_marker(
            conn,
            "demographic",
            slug,
            constituency.id,
            booth_id,
            booth_name,
            "",
            ""
          )
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

        not entry_marker_matches?(conn, slug, constituency_id, booth_id, booth_name, gender, age_group) ->
          conn
          |> put_flash(:error, "Invalid or expired voting flow. Please continue from the previous step.")
          |> redirect(
            to:
              ~p"/poll/#{slug}/demographic?constituency_id=#{constituency_id}&booth_id=#{booth_id}&booth_name=#{booth_name}"
          )

      true ->
        total_votes = Polling.count_votes(campaign.id, %{})
        constituency = Elections.get_constituency_by_user!(campaign.user_id, constituency_id)
        candidates = Elections.list_active_candidates_by_constituency(constituency.id)


        conn =
          issue_vote_token(
            conn,
            slug,
            constituency_id,
            booth_id,
            booth_name,
            gender,
            age_group
          )

        vote_token =
          get_session(conn, :poll_vote_token_context)["token"]

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
          error_message: nil,
          vote_token: vote_token
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
        booth = Elections.get_booth_by_constituency!(constituency.id, booth_id)

        attrs = %{
          "gender" => params["gender"],
          "age_group" => params["age_group"],
          "booth_id" => booth.id,
          "booth_name" => booth.name,
          "selfie_path" => nil,
          "latitude" => params["latitude"],
          "longitude" => params["longitude"],
          "submitted_at" => DateTime.utc_now() |> DateTime.truncate(:second),
          "campaign_id" => campaign.id,
          "constituency_id" => constituency.id,
          "candidate_id" => candidate_id,
          "voted_at" => params["voted_at"],
          "device_fingerprint" => params["device_fingerprint"]
        }

        Repo.transaction(fn ->
          case Polling.create_response(attrs) do
            {:ok, response} ->
              case SelfieStorage.save_response_selfie(params["selfie"], params["selfie_base64"], response.id) do
                {:ok, nil} ->
                  response

                {:ok, filename} ->
                  case Polling.update_response_selfie(response, filename) do
                    {:ok, updated_response} ->
                      updated_response

                    {:error, changeset} ->
                      Repo.rollback({:changeset, changeset})
                  end

                {:error, message} ->
                  Repo.rollback({:selfie_error, message})
              end

            {:error, changeset} ->
              Repo.rollback({:changeset, changeset})
          end
        end)
        |> case do
          {:ok, response} ->
            {:ok, response}

          {:error, {:changeset, _changeset}} ->
            {:error, "Please fill all required fields correctly."}

          {:error, {:selfie_error, message}} ->
            {:error, "Response saved, but selfie upload failed: #{message}"}

          {:error, _reason} ->
            {:error, "Unable to submit polling response."}
        end
    end
  end

  def submit_ajax(conn, %{"slug" => slug, "response" => response_params}) do
    try do
      vote_token = response_params["vote_token"]
      campaign = Elections.get_active_campaign_with_constituency_by_slug(slug)

      cond do
        is_nil(campaign) ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{ok: false, error: "Campaign not found or inactive."})

        not valid_vote_token?(conn, vote_token, slug, response_params) ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{ok: false, error: "Invalid or expired vote session. Please restart the voting flow."})

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

              conn = delete_session(conn, :poll_vote_token_context)

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
    rescue
      e ->
        IO.inspect(Exception.format(:error, e, __STACKTRACE__), label: "SUBMIT_AJAX ERROR")

        conn
        |> put_status(500)
        |> json(%{
          ok: false,
          error: "Internal server error",
          detail: Exception.message(e)
        })
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
        conn =
          put_vote_entry_marker(
            conn,
            "access",
            slug,
            constituency.id,
            booth_id,
            booth_name,
            gender,
            age_group
          )
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

  defp save_uploaded_selfie(%Plug.Upload{filename: filename, path: path}) do
    ext = Path.extname(filename)
    unique_name = "#{System.system_time(:millisecond)}#{ext}"

    Uploads.ensure_upload_dir!()
    dest = Uploads.file_path(unique_name)

    case File.cp(path, dest) do
      :ok -> {:ok, unique_name}
      {:error, _} -> {:error, "Unable to save selfie."}
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

      Uploads.ensure_upload_dir!()
      dest = Uploads.file_path(unique_name)

      case File.write(dest, binary) do
        :ok -> {:ok, unique_name}
        {:error, _} -> {:error, "Unable to save captured selfie."}
      end
    else
      _ -> {:error, "Invalid captured selfie data."}
    end
  end 

  defp save_selfie(_), do: {:error, "Invalid selfie upload."}

  defp put_vote_entry_marker(conn, stage, slug, constituency_id, booth_id, booth_name, gender, age_group) do
    context = %{
      "stage" => to_string(stage || ""),
      "slug" => to_string(slug || ""),
      "constituency_id" => to_string(constituency_id || ""),
      "booth_id" => to_string(booth_id || ""),
      "booth_name" => to_string(booth_name || ""),
      "gender" => to_string(gender || ""),
      "age_group" => to_string(age_group || "")
    }

    put_session(conn, :poll_vote_entry_context, context)
  end

  defp entry_marker_matches?(conn, slug, constituency_id, booth_id, booth_name, gender, age_group) do
    case get_session(conn, :poll_vote_entry_context) do
      %{
        "stage" => "demographic",
        "slug" => s,
        "constituency_id" => c,
        "booth_id" => b,
        "booth_name" => bn
      } ->
        s == to_string(slug || "") and
          c == to_string(constituency_id || "") and
          b == to_string(booth_id || "") and
          bn == to_string(booth_name || "")

      %{
        "stage" => "access",
        "slug" => s,
        "constituency_id" => c,
        "booth_id" => b,
        "booth_name" => bn,
        "gender" => g,
        "age_group" => a
      } ->
        s == to_string(slug || "") and
          c == to_string(constituency_id || "") and
          b == to_string(booth_id || "") and
          bn == to_string(booth_name || "") and
          g == to_string(gender || "") and
          a == to_string(age_group || "")

      _ ->
        false
    end
  end

  defp issue_vote_token(conn, slug, constituency_id, booth_id, booth_name, gender, age_group) do
    token = Base.url_encode64(:crypto.strong_rand_bytes(32), padding: false)

    context = %{
      "token" => token,
      "slug" => to_string(slug || ""),
      "constituency_id" => to_string(constituency_id || ""),
      "booth_id" => to_string(booth_id || ""),
      "booth_name" => to_string(booth_name || ""),
      "gender" => to_string(gender || ""),
      "age_group" => to_string(age_group || "")
    }

    conn
    |> put_session(:poll_vote_token_context, context)
    |> delete_session(:poll_vote_entry_context)
  end

  defp valid_vote_token?(conn, token, slug, response_params) do
    case get_session(conn, :poll_vote_token_context) do
      %{
        "token" => stored_token,
        "slug" => stored_slug,
        "constituency_id" => stored_constituency_id,
        "booth_id" => stored_booth_id,
        "booth_name" => stored_booth_name,
        "gender" => stored_gender,
        "age_group" => stored_age_group
      } ->
        stored_token == to_string(token || "") and
          stored_slug == to_string(slug || "") and
          stored_constituency_id == to_string(response_params["constituency_id"] || "") and
          stored_booth_id == to_string(response_params["booth_id"] || "") and
          stored_booth_name == to_string(response_params["booth_name"] || "") and
          stored_gender == to_string(response_params["gender"] || "") and
          stored_age_group == to_string(response_params["age_group"] || "")

      _ ->
        false
    end
  end
end