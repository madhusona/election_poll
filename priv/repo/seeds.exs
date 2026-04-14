alias ElectionPoll.Repo
alias ElectionPoll.Accounts
alias ElectionPoll.Accounts.User
alias ElectionPoll.Elections.State
alias ElectionPoll.Elections.Constituency
alias ElectionPoll.Elections.Candidate

user_email = "user@example.com"

user =
  Repo.get_by(User, email: user_email) ||
    case Accounts.register_user(%{
           email: user_email,
           password: "User@123456"
         }) do
      {:ok, user} -> user
      {:error, changeset} -> raise inspect(changeset.errors)
    end

# ensure role is public
user =
  user
  |> Ecto.Changeset.change(role: "public")
  |> Repo.update!()

IO.puts("Public user ready: #{user.email}")