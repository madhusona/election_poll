defmodule ElectionPoll.Accounts.UserAccessScope do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_access_scopes" do
    field :scope_type, :string
    field :scope_value, :string

    belongs_to :user, ElectionPoll.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(scope, attrs) do
    scope
    |> cast(attrs, [:user_id, :scope_type, :scope_value])
    |> validate_required([:user_id, :scope_type, :scope_value])
    |> unique_constraint(:scope_value, name: :user_access_scopes_unique_idx)
  end
end