defmodule ElectionPoll.Accounts.UserAccessScope do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_access_scopes" do
    field :scope_type, :string
    field :scope_value, :string
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_access_scope, attrs) do
    user_access_scope
    |> cast(attrs, [:scope_type, :scope_value])
    |> validate_required([:scope_type, :scope_value])
  end
end
