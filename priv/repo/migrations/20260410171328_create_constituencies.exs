defmodule ElectionPoll.Repo.Migrations.CreateConstituencies do
  use Ecto.Migration

  def change do
    create table(:constituencies) do
      add :name, :string
      add :code, :string
      add :display_order, :integer
      add :is_active, :boolean, default: false, null: false
      add :state_id, references(:states, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:constituencies, [:user_id])

    create index(:constituencies, [:state_id])
  end
end
