defmodule ElectionPoll.Accounts.UserAllowedCampaign do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_allowed_campaigns" do
    belongs_to :user, ElectionPoll.Accounts.User
    belongs_to :campaign, ElectionPoll.Elections.Campaign
    timestamps(type: :utc_datetime)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:user_id, :campaign_id])
    |> validate_required([:user_id, :campaign_id])
    |> unique_constraint([:user_id, :campaign_id])
  end
end