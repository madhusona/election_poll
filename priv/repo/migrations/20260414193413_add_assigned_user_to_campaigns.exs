defmodule ElectionPoll.Repo.Migrations.AddAssignedUserToCampaigns do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :assigned_user_id, references(:users, on_delete: :nilify_all)
    end

    create index(:campaigns, [:assigned_user_id])
  end
end