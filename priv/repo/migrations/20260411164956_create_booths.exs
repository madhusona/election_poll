defmodule ElectionPoll.Repo.Migrations.CreateBooths do
  use Ecto.Migration

  def change do
    create table(:booths) do
      add :name, :string, null: false
      add :code, :string
      add :status, :string, null: false, default: "Active"
      add :constituency_id, references(:constituencies, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:booths, [:constituency_id])
    create unique_index(:booths, [:constituency_id, :name])

  end
end
