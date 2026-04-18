defmodule ElectionPoll.Accounts.UserAllowedConstituency do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_allowed_constituencies" do
    belongs_to :user, ElectionPoll.Accounts.User
    belongs_to :constituency, ElectionPoll.Elections.Constituency
    timestamps(type: :utc_datetime)
  end

  def changeset(record, attrs) do
    record
    |> cast(attrs, [:user_id, :constituency_id])
    |> validate_required([:user_id, :constituency_id])
    |> unique_constraint([:user_id, :constituency_id])
  end
end