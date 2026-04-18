defmodule ElectionPoll.Elections.Constituency do
  use Ecto.Schema
  import Ecto.Changeset

  schema "constituencies" do
    field :name, :string
    field :code, :string
    field :display_order, :integer
    field :is_active, :boolean, default: false
    field :user_id, :id

    belongs_to :state, ElectionPoll.Elections.State

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(constituency, attrs) do
    constituency
    |> cast(attrs, [:name, :code, :display_order, :is_active, :state_id, :user_id])
    |> validate_required([:name, :code, :display_order, :is_active, :state_id])
    |> assoc_constraint(:state)
  end

  @doc false
  def changeset(constituency, attrs, user_scope) do
    constituency
    |> changeset(attrs)
    |> put_change(:user_id, user_scope.user.id)
  end
end