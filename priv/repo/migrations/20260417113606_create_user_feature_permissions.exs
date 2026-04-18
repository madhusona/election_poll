defmodule ElectionPoll.Repo.Migrations.CreateUserFeaturePermissions do
  use Ecto.Migration

  def change do
    create table(:user_feature_permissions) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :permissions, :map, null: false, default: %{}
      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_feature_permissions, [:user_id])
   
  end
end