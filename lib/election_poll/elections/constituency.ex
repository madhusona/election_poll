defmodule ElectionPoll.Elections.Constituency do
  use Ecto.Schema
  import Ecto.Changeset

  schema "constituencies" do
    field :name, :string
    field :code, :string
    field :display_order, :integer
    field :is_active, :boolean, default: false
    field :state_id, :id
    field :user_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(constituency, attrs, user_scope) do
    constituency
    |> cast(attrs, [:name, :code, :display_order, :is_active])
    |> validate_required([:name, :code, :display_order, :is_active])
    |> put_change(:user_id, user_scope.user.id)
  end
end
