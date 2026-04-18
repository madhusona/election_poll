defmodule ElectionPoll.Elections.Booth do
  use Ecto.Schema
  import Ecto.Changeset

  alias ElectionPoll.Accounts.Scope

  schema "booths" do
    field :name, :string
    field :code, :string
    field :status, :string, default: "Active"

    belongs_to :constituency, ElectionPoll.Elections.Constituency

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(booth, attrs) do
    booth
    |> cast(attrs, [:name, :code, :status, :constituency_id])
    |> validate_required([:name, :status, :constituency_id])
    |> validate_inclusion(:status, ["Active", "Inactive"])
    |> assoc_constraint(:constituency)
  end

  @doc false
  def changeset(booth, attrs, %Scope{}) do
    changeset(booth, attrs)
  end
end