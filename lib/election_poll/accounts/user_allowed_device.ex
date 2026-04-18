defmodule ElectionPoll.Accounts.UserAllowedDevice do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_allowed_devices" do
    belongs_to :user, ElectionPoll.Accounts.User
    field :device_fingerprint, :string
    timestamps(type: :utc_datetime)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:user_id, :device_fingerprint])
    |> validate_required([:user_id, :device_fingerprint])
    |> unique_constraint(:device_fingerprint,
         name: :user_allowed_devices_user_id_device_fingerprint_index
       )
  end
end