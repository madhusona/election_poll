alias ElectionPoll.Accounts
alias ElectionPoll.Repo

{:ok, user} =
  Accounts.register_user(%{
    email: "admin@votegrid.in",
    password: "prasana1988"
  })

user
|> Ecto.Changeset.change(role: "admin")
|> Repo.update!()
