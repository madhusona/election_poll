defmodule ElectionPoll.Repo.Migrations.CreateCandidates do
  use Ecto.Migration

  def change do
    create table(:candidates) do
      add :candidate_name, :string
      add :party_full_name, :string
      add :abbreviation, :string
      add :alliance, :string
      add :display_order, :integer
      add :symbol_image, :string
      add :symbol_name, :string
      add :color, :string
      add :is_active, :boolean, default: false, null: false
      add :constituency_id, references(:constituencies, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:candidates, [:user_id])

    create index(:candidates, [:constituency_id])
  end
end
