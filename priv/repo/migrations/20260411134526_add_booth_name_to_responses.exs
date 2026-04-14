defmodule ElectionPoll.Repo.Migrations.AddBoothNameToResponses do
  use Ecto.Migration

  def change do
    alter table(:responses) do
      add :booth_name, :string
    end

  end
end
