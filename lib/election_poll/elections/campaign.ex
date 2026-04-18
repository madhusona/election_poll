defmodule ElectionPoll.Elections.Campaign do
  use Ecto.Schema
  import Ecto.Changeset

  alias ElectionPoll.Accounts.Scope

  schema "campaigns" do
    field :name, :string
    field :slug, :string
    field :secret_code, :string
    field :is_active, :boolean, default: true
    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime

    belongs_to :user, ElectionPoll.Accounts.User
    belongs_to :constituency, ElectionPoll.Elections.Constituency
    belongs_to :assigned_user, ElectionPoll.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(campaign, attrs) do
    campaign
    |> cast(attrs, [
      :name,
      :slug,
      :secret_code,
      :is_active,
      :starts_at,
      :ends_at,
      :constituency_id,
      :assigned_user_id,
      :user_id
    ])
    |> validate_required([
      :name,
      :slug,
      :secret_code,
      :is_active,
      :starts_at,
      :ends_at,
      :constituency_id
    ])
    |> assoc_constraint(:constituency)
    |> unique_constraint(:slug)
  end

  @doc false
  def changeset(campaign, attrs, %Scope{} = scope) do
    campaign
    |> changeset(attrs)
    |> put_change(:user_id, scope.user.id)
  end
end