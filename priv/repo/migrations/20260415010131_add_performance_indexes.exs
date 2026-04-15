defmodule ElectionPoll.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create_if_not_exists index(:responses, [:campaign_id], concurrently: true)
    create_if_not_exists index(:responses, [:campaign_id, :candidate_id], concurrently: true)
    create_if_not_exists index(:responses, [:campaign_id, :submitted_at], concurrently: true)

    create_if_not_exists index(:responses, [:campaign_id, :gender], concurrently: true)
    create_if_not_exists index(:responses, [:campaign_id, :age_group], concurrently: true)
    create_if_not_exists index(:responses, [:campaign_id, :booth_id], concurrently: true)

    create_if_not_exists index(:responses, [:constituency_id], concurrently: true)

    create_if_not_exists unique_index(:users, [:email], concurrently: true)
    create_if_not_exists unique_index(:campaigns, [:slug], concurrently: true)

    create_if_not_exists index(:users, [:role], concurrently: true)
    create_if_not_exists index(:candidates, [:constituency_id], concurrently: true)
    create_if_not_exists index(:booths, [:constituency_id], concurrently: true)
  end
end
