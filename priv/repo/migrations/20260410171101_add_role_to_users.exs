defmodule ElectionPoll.Repo.Migrations.AddRoleToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :role, :string, default: "public", null: false
    end

  end
end
