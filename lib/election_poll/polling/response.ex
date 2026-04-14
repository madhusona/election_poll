defmodule ElectionPoll.Polling.Response do
  use Ecto.Schema
  import Ecto.Changeset

  schema "responses" do
    field :voter_name, :string
    field :mobile, :string
    field :gender, :string
    field :age_group, :string
    field :selfie_path, :string
    field :latitude, :float
    field :longitude, :float
    field :submitted_at, :utc_datetime
    field :voted_at, :utc_datetime
    field :device_fingerprint, :string
    field :booth_name, :string

    belongs_to :booth, ElectionPoll.Elections.Booth
    belongs_to :campaign, ElectionPoll.Elections.Campaign
    belongs_to :constituency, ElectionPoll.Elections.Constituency
    belongs_to :candidate, ElectionPoll.Elections.Candidate

    timestamps(type: :utc_datetime)
  end

  def changeset(response, attrs) do
    response
    |> cast(attrs, [
      :gender,
      :age_group,
      :selfie_path,
      :latitude,
      :longitude,
      :submitted_at,
      :voted_at,
      :device_fingerprint,
      :campaign_id,
      :constituency_id,
      :candidate_id,
      :booth_id,
      :booth_name
    ])
    |> validate_required([
      :gender,
      :age_group,
      :selfie_path,
      :latitude,
      :longitude,
      :submitted_at,
      :voted_at,
      :device_fingerprint,
      :campaign_id,
      :constituency_id,
      :candidate_id,
      :booth_id,
      :booth_name
    ])
    |> validate_inclusion(:gender, ["Male", "Female", "Other"])
    |> validate_inclusion(:age_group, ["18-20", "20-40", "40-60", "60+"])
    |> foreign_key_constraint(:campaign_id)
    |> foreign_key_constraint(:constituency_id)
    |> foreign_key_constraint(:candidate_id)
    |> foreign_key_constraint(:booth_id)
  end
end