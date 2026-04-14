defmodule ElectionPoll.Repo.Migrations.AddVoteMetadataToResponses do
  use Ecto.Migration

  def change do
    alter table(:responses) do
      add :voted_at, :utc_datetime
      add :device_fingerprint, :text
    end
  end
end