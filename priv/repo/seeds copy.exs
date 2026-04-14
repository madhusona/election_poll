alias ElectionPoll.Repo
alias ElectionPoll.Accounts
alias ElectionPoll.Accounts.User
alias ElectionPoll.Elections.State
alias ElectionPoll.Elections.Constituency
alias ElectionPoll.Elections.Candidate

admin_email = "admin@example.com"

admin =
  Repo.get_by(User, email: admin_email) ||
    case Accounts.register_user(%{
           email: admin_email,
           password: "Admin@123456"
         }) do
      {:ok, user} -> user
      {:error, changeset} -> raise inspect(changeset.errors)
    end

admin =
  admin
  |> Ecto.Changeset.change(role: "admin")
  |> Repo.update!()

IO.puts("Admin ready: #{admin.email}")

tn =
  Repo.get_by(State, code: "TN") ||
    Repo.insert!(%State{
      name: "Tamil Nadu",
      code: "TN",
      display_order: 1,
      is_active: true
    })

py =
  Repo.get_by(State, code: "PY") ||
    Repo.insert!(%State{
      name: "Puducherry",
      code: "PY",
      display_order: 2,
      is_active: true
    })

chennai_central =
  Repo.get_by(Constituency, code: "CHE-CEN") ||
    Repo.insert!(%Constituency{
      name: "Chennai Central",
      code: "CHE-CEN",
      display_order: 1,
      is_active: true,
      state_id: tn.id
    })

pondicherry =
  Repo.get_by(Constituency, code: "PUD-1") ||
    Repo.insert!(%Constituency{
      name: "Puducherry",
      code: "PUD-1",
      display_order: 1,
      is_active: true,
      state_id: py.id
    })

Repo.get_by(Candidate, candidate_name: "Candidate A", constituency_id: chennai_central.id) ||
  Repo.insert!(%Candidate{
    candidate_name: "Candidate A",
    party_full_name: "Party A",
    abbreviation: "PA",
    alliance: "Alliance 1",
    display_order: 1,
    symbol_image: "a.png",
    symbol_name: "Symbol A",
    color: "#FF0000",
    is_active: true,
    constituency_id: chennai_central.id
  })

Repo.get_by(Candidate, candidate_name: "Candidate B", constituency_id: chennai_central.id) ||
  Repo.insert!(%Candidate{
    candidate_name: "Candidate B",
    party_full_name: "Party B",
    abbreviation: "PB",
    alliance: "Alliance 2",
    display_order: 2,
    symbol_image: "b.png",
    symbol_name: "Symbol B",
    color: "#00FF00",
    is_active: true,
    constituency_id: chennai_central.id
  })

Repo.get_by(Candidate, candidate_name: "Candidate C", constituency_id: pondicherry.id) ||
  Repo.insert!(%Candidate{
    candidate_name: "Candidate C",
    party_full_name: "Party C",
    abbreviation: "PC",
    alliance: "Alliance 1",
    display_order: 1,
    symbol_image: "c.png",
    symbol_name: "Symbol C",
    color: "#0000FF",
    is_active: true,
    constituency_id: pondicherry.id
  })

IO.puts("Seed completed.")