alias ElectionPoll.Repo

alias ElectionPoll.Accounts.User
alias ElectionPoll.Accounts.{
  UserAllowedCampaign,
  UserAllowedState,
  UserAllowedConstituency,
  UserAllowedDevice,
  UserFeaturePermission
}

alias ElectionPoll.Elections.{
  State,
  Constituency,
  Campaign,
  Booth,
  Candidate
}

alias ElectionPoll.Polling.Response

import Ecto.Query

now = DateTime.utc_now() |> DateTime.truncate(:second)
same_password = "Password@123456"
admin_email = "admin@votegrid.in"

# --------------------------------------------------
# Helpers
# --------------------------------------------------

find_admin =
  Repo.get_by!(User, email: admin_email)

admin =
  find_admin
  |> Ecto.Changeset.change(%{
    hashed_password: Bcrypt.hash_pwd_salt(same_password),
    confirmed_at: find_admin.confirmed_at || now,
    role: "admin",
    updated_at: now
  })
  |> Repo.update!()

truthy_permissions = %{
  "can_view_responses" => true,
  "can_view_response_detail" => true,
  "can_export_responses" => false,
  "can_view_selfie" => false,
  "can_view_location" => true,
  "can_view_exact_coordinates" => false,
  "can_view_device_fingerprint" => false,
  "can_view_voter_name" => false,
  "can_view_mobile" => false
}

create_user = fn email, role ->
  %User{}
  |> Ecto.Changeset.change(%{
    email: email,
    hashed_password: Bcrypt.hash_pwd_salt(same_password),
    confirmed_at: now,
    role: role,
    inserted_at: now,
    updated_at: now
  })
  |> Repo.insert!()
end

create_state = fn attrs ->
  %State{}
  |> Ecto.Changeset.change(Map.merge(attrs, %{inserted_at: now, updated_at: now}))
  |> Repo.insert!()
end

create_constituency = fn attrs ->
  %Constituency{}
  |> Ecto.Changeset.change(Map.merge(attrs, %{inserted_at: now, updated_at: now}))
  |> Repo.insert!()
end

create_campaign = fn attrs ->
  %Campaign{}
  |> Ecto.Changeset.change(Map.merge(attrs, %{inserted_at: now, updated_at: now}))
  |> Repo.insert!()
end

create_booth = fn attrs ->
  %Booth{}
  |> Ecto.Changeset.change(Map.merge(attrs, %{inserted_at: now, updated_at: now}))
  |> Repo.insert!()
end

create_candidate = fn attrs ->
  %Candidate{}
  |> Ecto.Changeset.change(Map.merge(attrs, %{inserted_at: now, updated_at: now}))
  |> Repo.insert!()
end

insert_allowed_state = fn user_id, state_id ->
  %UserAllowedState{}
  |> Ecto.Changeset.change(%{
    user_id: user_id,
    state_id: state_id,
    inserted_at: now,
    updated_at: now
  })
  |> Repo.insert!()
end

insert_allowed_constituency = fn user_id, constituency_id ->
  %UserAllowedConstituency{}
  |> Ecto.Changeset.change(%{
    user_id: user_id,
    constituency_id: constituency_id,
    inserted_at: now,
    updated_at: now
  })
  |> Repo.insert!()
end

insert_allowed_campaign = fn user_id, campaign_id ->
  %UserAllowedCampaign{}
  |> Ecto.Changeset.change(%{
    user_id: user_id,
    campaign_id: campaign_id,
    inserted_at: now,
    updated_at: now
  })
  |> Repo.insert!()
end

insert_feature_permissions = fn user_id, permissions ->
  %UserFeaturePermission{}
  |> Ecto.Changeset.change(%{
    user_id: user_id,
    permissions: permissions,
    inserted_at: now,
    updated_at: now
  })
  |> Repo.insert!()
end

create_response = fn attrs ->
  %Response{}
  |> Response.changeset(attrs)
  |> Repo.insert!()
end

# --------------------------------------------------
# 1. DELETE all test data except admin
# --------------------------------------------------

admin_id = admin.id

Repo.delete_all(UserAllowedDevice)
Repo.delete_all(UserAllowedCampaign)
Repo.delete_all(UserAllowedState)
Repo.delete_all(UserAllowedConstituency)
Repo.delete_all(UserFeaturePermission)
Repo.delete_all(Response)
Repo.delete_all(Candidate)
Repo.delete_all(Booth)
Repo.delete_all(Campaign)
Repo.delete_all(Constituency)
Repo.delete_all(State)

from(u in User, where: u.id != ^admin_id)
|> Repo.delete_all()

# --------------------------------------------------
# 2. Create 5 subadmins
# --------------------------------------------------

subadmin1 = create_user.("subadmin1@votegrid.in", "subadmin")
subadmin2 = create_user.("subadmin2@votegrid.in", "subadmin")
subadmin3 = create_user.("subadmin3@votegrid.in", "subadmin")
subadmin4 = create_user.("subadmin4@votegrid.in", "subadmin")
subadmin5 = create_user.("subadmin5@votegrid.in", "subadmin")

# --------------------------------------------------
# 3. Create states
# --------------------------------------------------

tamil_nadu =
  create_state.(%{
    name: "Tamil Nadu",
    code: "TN",
    display_order: 1,
    is_active: true,
    user_id: admin.id
  })

puducherry_state =
  create_state.(%{
    name: "Puducherry",
    code: "PY",
    display_order: 2,
    is_active: true,
    user_id: admin.id
  })

# --------------------------------------------------
# 4. Create constituencies
# --------------------------------------------------

veerapandi =
  create_constituency.(%{
    name: "Veerapandi",
    code: "TN-VEERAPANDI",
    display_order: 1,
    is_active: true,
    state_id: tamil_nadu.id,
    user_id: admin.id
  })

salem_south =
  create_constituency.(%{
    name: "Salem South",
    code: "TN-SALEM-SOUTH",
    display_order: 2,
    is_active: true,
    state_id: tamil_nadu.id,
    user_id: admin.id
  })

coimbatore_south =
  create_constituency.(%{
    name: "Coimbatore South",
    code: "TN-COIMBATORE-SOUTH",
    display_order: 3,
    is_active: true,
    state_id: tamil_nadu.id,
    user_id: admin.id
  })

puducherry =
  create_constituency.(%{
    name: "Puducherry",
    code: "PY-PUDUCHERRY",
    display_order: 1,
    is_active: true,
    state_id: puducherry_state.id,
    user_id: admin.id
  })

oulgaret =
  create_constituency.(%{
    name: "Oulgaret",
    code: "PY-OULGARET",
    display_order: 2,
    is_active: true,
    state_id: puducherry_state.id,
    user_id: admin.id
  })

villianur =
  create_constituency.(%{
    name: "Villianur",
    code: "PY-VILLIANUR",
    display_order: 3,
    is_active: true,
    state_id: puducherry_state.id,
    user_id: admin.id
  })

# --------------------------------------------------
# 5. Create sample booths (1 per constituency)
# --------------------------------------------------

booth_veerapandi =
  create_booth.(%{
    name: "Veerapandi Booth 1",
    code: "VP-001",
    status: "Active",
    constituency_id: veerapandi.id
  })

booth_salem =
  create_booth.(%{
    name: "Salem South Booth 1",
    code: "SS-001",
    status: "Active",
    constituency_id: salem_south.id
  })

booth_coimbatore =
  create_booth.(%{
    name: "Coimbatore South Booth 1",
    code: "CS-001",
    status: "Active",
    constituency_id: coimbatore_south.id
  })

booth_puducherry =
  create_booth.(%{
    name: "Puducherry Booth 1",
    code: "PDY-001",
    status: "Active",
    constituency_id: puducherry.id
  })

booth_oulgaret =
  create_booth.(%{
    name: "Oulgaret Booth 1",
    code: "OUL-001",
    status: "Active",
    constituency_id: oulgaret.id
  })

booth_villianur =
  create_booth.(%{
    name: "Villianur Booth 1",
    code: "VIL-001",
    status: "Active",
    constituency_id: villianur.id
  })

# --------------------------------------------------
# 6. Create campaigns
# --------------------------------------------------

start_at = ~U[2026-04-01 00:00:00Z]
end_at   = ~U[2026-12-31 23:59:59Z]

camp_veerapandi =
  create_campaign.(%{
    name: "Veerapandi Campaign A",
    slug: "veerapandi-a",
    secret_code: "VP001",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: veerapandi.id,
    user_id: admin.id,
    assigned_user_id: subadmin1.id
  })

camp_salem =
  create_campaign.(%{
    name: "Salem South Campaign A",
    slug: "salem-south-a",
    secret_code: "SS001",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: salem_south.id,
    user_id: admin.id,
    assigned_user_id: subadmin2.id
  })

camp_coimbatore =
  create_campaign.(%{
    name: "Coimbatore South Campaign A",
    slug: "coimbatore-south-a",
    secret_code: "CS001",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: coimbatore_south.id,
    user_id: admin.id,
    assigned_user_id: subadmin2.id
  })

camp_puducherry =
  create_campaign.(%{
    name: "Puducherry Campaign A",
    slug: "puducherry-a",
    secret_code: "PY001",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: puducherry.id,
    user_id: admin.id,
    assigned_user_id: subadmin3.id
  })

camp_oulgaret =
  create_campaign.(%{
    name: "Oulgaret Campaign A",
    slug: "oulgaret-a",
    secret_code: "OU001",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: oulgaret.id,
    user_id: admin.id,
    assigned_user_id: subadmin4.id
  })

camp_villianur =
  create_campaign.(%{
    name: "Villianur Campaign A",
    slug: "villianur-a",
    secret_code: "VI001",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: villianur.id,
    user_id: admin.id,
    assigned_user_id: subadmin5.id
  })

# --------------------------------------------------
# 7. Create candidates (3 per constituency)
# --------------------------------------------------

constituency_candidates = fn constituency ->
  [
    create_candidate.(%{
      candidate_name: "#{constituency.name} Candidate 1",
      party_full_name: "Party A",
      abbreviation: "PA",
      alliance: "Alliance A",
      display_order: 1,
      symbol_name: "Rising Sun",
      color: "#ef4444",
      symbol_image: "",
      is_active: true,
      constituency_id: constituency.id,
      user_id: admin.id
    }),
    create_candidate.(%{
      candidate_name: "#{constituency.name} Candidate 2",
      party_full_name: "Party B",
      abbreviation: "PB",
      alliance: "Alliance B",
      display_order: 2,
      symbol_name: "Two Leaves",
      color: "#22c55e",
      symbol_image: "",
      is_active: true,
      constituency_id: constituency.id,
      user_id: admin.id
    }),
    create_candidate.(%{
      candidate_name: "#{constituency.name} Candidate 3",
      party_full_name: "Independent",
      abbreviation: "IND",
      alliance: "Independent",
      display_order: 3,
      symbol_name: "Whistle",
      color: "#3b82f6",
      symbol_image: "",
      is_active: true,
      constituency_id: constituency.id,
      user_id: admin.id
    })
  ]
end

veerapandi_candidates = constituency_candidates.(veerapandi)
salem_candidates = constituency_candidates.(salem_south)
coimbatore_candidates = constituency_candidates.(coimbatore_south)
puducherry_candidates = constituency_candidates.(puducherry)
oulgaret_candidates = constituency_candidates.(oulgaret)
villianur_candidates = constituency_candidates.(villianur)

# --------------------------------------------------
# 8. Restrictions
# --------------------------------------------------

insert_allowed_state.(subadmin1.id, tamil_nadu.id)
insert_allowed_constituency.(subadmin1.id, veerapandi.id)
insert_allowed_campaign.(subadmin1.id, camp_veerapandi.id)
insert_feature_permissions.(subadmin1.id, truthy_permissions)

insert_allowed_state.(subadmin2.id, tamil_nadu.id)
insert_allowed_constituency.(subadmin2.id, salem_south.id)
insert_allowed_constituency.(subadmin2.id, coimbatore_south.id)
insert_allowed_campaign.(subadmin2.id, camp_salem.id)
insert_allowed_campaign.(subadmin2.id, camp_coimbatore.id)
insert_feature_permissions.(subadmin2.id, truthy_permissions)

insert_allowed_state.(subadmin3.id, puducherry_state.id)
insert_allowed_constituency.(subadmin3.id, puducherry.id)
insert_allowed_campaign.(subadmin3.id, camp_puducherry.id)
insert_feature_permissions.(subadmin3.id, truthy_permissions)

insert_allowed_state.(subadmin4.id, puducherry_state.id)
insert_allowed_constituency.(subadmin4.id, oulgaret.id)
insert_allowed_campaign.(subadmin4.id, camp_oulgaret.id)
insert_feature_permissions.(subadmin4.id, truthy_permissions)

insert_allowed_state.(subadmin5.id, puducherry_state.id)
insert_allowed_constituency.(subadmin5.id, villianur.id)
insert_allowed_campaign.(subadmin5.id, camp_villianur.id)
insert_feature_permissions.(subadmin5.id, truthy_permissions)

# --------------------------------------------------
# 9. Responses: 2 responses per candidate per constituency
# --------------------------------------------------

insert_two_per_candidate = fn campaign, constituency, booth, candidates ->
  Enum.with_index(candidates, 1)
  |> Enum.each(fn {candidate, idx} ->
    create_response.(%{
        campaign_id: campaign.id,
        constituency_id: constituency.id,
        booth_id: booth.id,
        candidate_id: candidate.id,
        booth_name: booth.name,
        voter_name: "Test Voter #{constituency.id}-#{idx}-1",
        mobile: "900000#{constituency.id}#{idx}1",
        gender: "Male",
        age_group: "20-40",
        latitude: 11.0 + constituency.id / 100,
        longitude: 79.0 + constituency.id / 100,
        device_fingerprint: "device-#{constituency.id}-#{idx}-1",
        selfie_path: "",
        submitted_at: now,
        voted_at: now
        })
    create_response.(%{
        campaign_id: campaign.id,
        constituency_id: constituency.id,
        booth_id: booth.id,
        candidate_id: candidate.id,
        booth_name: booth.name,
        voter_name: "Test Voter #{constituency.id}-#{idx}-2",
        mobile: "900000#{constituency.id}#{idx}2",
        gender: "Female",
        age_group: "40-60",
        latitude: 11.5 + constituency.id / 100,
        longitude: 79.5 + constituency.id / 100,
        device_fingerprint: "device-#{constituency.id}-#{idx}-2",
        selfie_path: "",
        submitted_at: now,
        voted_at: now
        })
  end)
end

insert_two_per_candidate.(camp_veerapandi, veerapandi, booth_veerapandi, veerapandi_candidates)
insert_two_per_candidate.(camp_salem, salem_south, booth_salem, salem_candidates)
insert_two_per_candidate.(camp_coimbatore, coimbatore_south, booth_coimbatore, coimbatore_candidates)
insert_two_per_candidate.(camp_puducherry, puducherry, booth_puducherry, puducherry_candidates)
insert_two_per_candidate.(camp_oulgaret, oulgaret, booth_oulgaret, oulgaret_candidates)
insert_two_per_candidate.(camp_villianur, villianur, booth_villianur, villianur_candidates)

IO.puts("Reset test data completed successfully.")
IO.puts("Admin kept: #{admin.email}")
IO.puts("Subadmins created with same password: #{same_password}")