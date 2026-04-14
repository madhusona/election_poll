defmodule ElectionPoll.Repo.Migrations.CreateResponses do
  use Ecto.Migration

  def change do
    create table(:responses) do
      add :voter_name, :string
      add :mobile, :string
      add :secret_code, :string
      add :selfie_path, :string
      add :latitude, :float
      add :longitude, :float
      add :submitted_at, :utc_datetime
      add :constituency_id, references(:constituencies, on_delete: :nothing)
      add :candidate_id, references(:candidates, on_delete: :nothing)
      add :user_id, references(:users, type: :id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:responses, [:user_id])

    create index(:responses, [:constituency_id])
    create index(:responses, [:candidate_id])
  end
end
