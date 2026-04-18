defmodule ElectionPoll.Repo.Migrations.CreateUserAccessScopes do
  use Ecto.Migration

  def change do
    create table(:user_access_scopes) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :scope_type, :string, null: false
      add :scope_value, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:user_access_scopes, [:user_id])
    create index(:user_access_scopes, [:scope_type])

    create unique_index(
      :user_access_scopes,
      [:user_id, :scope_type, :scope_value],
      name: :user_access_scopes_unique_idx
    )
  end
end