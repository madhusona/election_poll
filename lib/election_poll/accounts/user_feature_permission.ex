defmodule ElectionPoll.Accounts.UserFeaturePermission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_feature_permissions" do
    belongs_to :user, ElectionPoll.Accounts.User
    field :permissions, :map, default: %{}
    timestamps(type: :utc_datetime)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:user_id, :permissions])
    |> validate_required([:user_id, :permissions])
    |> unique_constraint(:user_id)
  end
end