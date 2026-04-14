defmodule ElectionPoll.Elections.Candidate do
  use Ecto.Schema
  import Ecto.Changeset

  alias ElectionPoll.Accounts.Scope

  schema "candidates" do
    field :candidate_name, :string
    field :party_full_name, :string
    field :abbreviation, :string
    field :alliance, :string
    field :display_order, :integer
    field :symbol_image, :string
    field :symbol_name, :string
    field :color, :string
    field :is_active, :boolean, default: false

    belongs_to :constituency, ElectionPoll.Elections.Constituency
    belongs_to :user, ElectionPoll.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(candidate, attrs, %Scope{} = scope) do
    candidate
    |> cast(attrs, [
      :candidate_name,
      :party_full_name,
      :abbreviation,
      :alliance,
      :display_order,
      :symbol_image,
      :symbol_name,
      :color,
      :is_active,
      :constituency_id
    ])
    |> validate_required([
      :candidate_name,
      :party_full_name,
      :abbreviation,
      :alliance,
      :display_order,
      :symbol_name,
      :color,
      :constituency_id
    ])
    |> put_change(:user_id, scope.user.id)
  end
end