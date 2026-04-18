defmodule ElectionPoll.Accounts.UserAllowedState do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_allowed_states" do
    belongs_to :user, ElectionPoll.Accounts.User
    belongs_to :state, ElectionPoll.Elections.State
    timestamps(type: :utc_datetime)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:user_id, :state_id])
    |> validate_required([:user_id, :state_id])
    |> unique_constraint([:user_id, :state_id])
  end
end