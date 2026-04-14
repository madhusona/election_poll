defmodule ElectionPoll.Repo.Migrations.AddCampaignIdToResponses do
  use Ecto.Migration

  def change do
    alter table(:responses) do
      add :campaign_id, references(:campaigns, on_delete: :nothing)
    end

    create index(:responses, [:campaign_id])

  end
end


