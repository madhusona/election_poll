defmodule ElectionPoll.Repo.Migrations.CreateUserAccessControls do
  use Ecto.Migration

  def change do
    create table(:user_allowed_campaigns) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_allowed_campaigns, [:user_id, :campaign_id])
    create index(:user_allowed_campaigns, [:user_id])
    create index(:user_allowed_campaigns, [:campaign_id])

    create table(:user_allowed_states) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :state_id, references(:states, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_allowed_states, [:user_id, :state_id])
    create index(:user_allowed_states, [:user_id])
    create index(:user_allowed_states, [:state_id])

    create table(:user_allowed_constituencies) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :constituency_id, references(:constituencies, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_allowed_constituencies, [:user_id, :constituency_id])
    create index(:user_allowed_constituencies, [:user_id])
    create index(:user_allowed_constituencies, [:constituency_id])

    create table(:user_allowed_devices) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :device_fingerprint, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_allowed_devices, [:user_id, :device_fingerprint],
             name: :user_allowed_devices_user_id_device_fingerprint_index
           )

    create index(:user_allowed_devices, [:user_id])
  end
end