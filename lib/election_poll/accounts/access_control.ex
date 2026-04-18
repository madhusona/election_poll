defmodule ElectionPoll.Accounts.AccessControl do
  import Ecto.Query, warn: false

  alias ElectionPoll.Repo
  alias ElectionPoll.Accounts.{
    UserAllowedCampaign,
    UserAllowedState,
    UserAllowedConstituency,
    UserAllowedDevice,
    UserFeaturePermission
  }

  @default_permissions %{
    "can_view_responses" => true,
    "can_view_response_detail" => true,
    "can_export_responses" => false,
    "can_view_selfie" => false,
    "can_view_location" => false,
    "can_view_exact_coordinates" => false,
    "can_view_device_fingerprint" => false,
    "can_view_voter_name" => false,
    "can_view_mobile" => false
  }

  def allowed_scope(%{role: "admin"}) do
    %{
      campaign_ids: [],
      state_ids: [],
      constituency_ids: [],
      device_fingerprints: []
    }
  end

  def allowed_scope(user) do
    %{
      campaign_ids: allowed_campaign_ids(user.id),
      state_ids: allowed_state_ids(user.id),
      constituency_ids: allowed_constituency_ids(user.id),
      device_fingerprints: allowed_device_fingerprints(user.id)
    }
  end

  def feature_permissions(%{role: "admin"}) do
    Map.merge(@default_permissions, %{
      "can_export_responses" => true,
      "can_view_selfie" => true,
      "can_view_location" => true,
      "can_view_exact_coordinates" => true,
      "can_view_device_fingerprint" => true,
      "can_view_voter_name" => true,
      "can_view_mobile" => true
    })
  end

  def feature_permissions(user) do
    permissions =
      UserFeaturePermission
      |> where([p], p.user_id == ^user.id)
      |> select([p], p.permissions)
      |> Repo.one()

    Map.merge(@default_permissions, permissions || %{})
  end

  def allowed_campaign_ids(user_id) do
    UserAllowedCampaign
    |> where([x], x.user_id == ^user_id)
    |> select([x], x.campaign_id)
    |> Repo.all()
  end

  def allowed_state_ids(user_id) do
    UserAllowedState
    |> where([x], x.user_id == ^user_id)
    |> select([x], x.state_id)
    |> Repo.all()
  end

  def allowed_constituency_ids(user_id) do
    UserAllowedConstituency
    |> where([x], x.user_id == ^user_id)
    |> select([x], x.constituency_id)
    |> Repo.all()
  end

  def allowed_device_fingerprints(user_id) do
    UserAllowedDevice
    |> where([x], x.user_id == ^user_id)
    |> select([x], x.device_fingerprint)
    |> Repo.all()
  end
end