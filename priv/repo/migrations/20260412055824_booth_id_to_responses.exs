defmodule ElectionPoll.Repo.Migrations.BoothIdToResponses do
  use Ecto.Migration

  def change do
    alter table(:responses) do
      add :booth_id, references(:booths, on_delete: :nilify_all)
    end

    create index(:responses, [:booth_id])
    create index(:responses, [:campaign_id, :booth_id])

  end
end
