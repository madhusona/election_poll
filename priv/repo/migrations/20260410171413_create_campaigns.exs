defmodule ElectionPoll.Repo.Migrations.CreateCampaigns do
  use Ecto.Migration

  def change do
    create table(:campaigns) do
      add :name, :string
      add :slug, :string
      add :secret_code, :string
      add :is_active, :boolean, default: false, null: false
      add :starts_at, :utc_datetime
      add :ends_at, :utc_datetime
      add :constituency_id, references(:constituencies, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:campaigns, [:user_id])

    create index(:campaigns, [:constituency_id])
  end
end
