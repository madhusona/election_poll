defmodule ElectionPoll.Elections.Booth do
  use Ecto.Schema
  import Ecto.Changeset

  schema "booths" do
    field :name, :string
    field :code, :string
    field :status, :string, default: "Active"

    belongs_to :constituency, ElectionPoll.Elections.Constituency

    timestamps()
  end

  def changeset(booth, attrs) do
    booth
    |> cast(attrs, [:name, :code, :status, :constituency_id])
    |> validate_required([:name, :status, :constituency_id])
    |> validate_inclusion(:status, ["Active", "Inactive"])
    |> unique_constraint([:constituency_id, :name])
  end
end