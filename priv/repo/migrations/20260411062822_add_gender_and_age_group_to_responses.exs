defmodule ElectionPoll.Repo.Migrations.AddGenderAndAgeGroupToResponses do
  use Ecto.Migration

  def change do
    alter table(:responses) do
    add :gender, :string
    add :age_group, :string
  end

  end
end
