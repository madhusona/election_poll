alias ElectionPoll.Repo

alias ElectionPoll.Accounts.User
alias ElectionPoll.Accounts.{
  UserAllowedCampaign,
  UserAllowedState,
  UserAllowedConstituency,
  UserFeaturePermission
}

alias ElectionPoll.Elections.{
  State,
  Constituency,
  Campaign
}

# --------------------------------------------------
# Helpers
# --------------------------------------------------

now = DateTime.utc_now() |> DateTime.truncate(:second)

find_or_create_user = fn email, role ->
  case Repo.get_by(User, email: email) do
    nil ->
      %User{}
      |> Ecto.Changeset.change(%{
        email: email,
        hashed_password: Bcrypt.hash_pwd_salt("Password@123456"),
        confirmed_at: now,
        role: role
      })
      |> Repo.insert!()

    user ->
      user
  end
end

find_or_create_state = fn attrs ->
  case Repo.get_by(State, code: attrs.code) do
    nil ->
      %State{}
      |> Ecto.Changeset.change(Map.merge(attrs, %{inserted_at: now, updated_at: now}))
      |> Repo.insert!()

    state ->
      state
  end
end

find_or_create_constituency = fn attrs ->
  case Repo.get_by(Constituency, code: attrs.code) do
    nil ->
      %Constituency{}
      |> Ecto.Changeset.change(Map.merge(attrs, %{inserted_at: now, updated_at: now}))
      |> Repo.insert!()

    constituency ->
      constituency
  end
end

find_or_create_campaign = fn attrs ->
  case Repo.get_by(Campaign, slug: attrs.slug) do
    nil ->
      %Campaign{}
      |> Ecto.Changeset.change(Map.merge(attrs, %{inserted_at: now, updated_at: now}))
      |> Repo.insert!()

    campaign ->
      campaign
  end
end

insert_allowed_state = fn user_id, state_id ->
  case Repo.get_by(UserAllowedState, user_id: user_id, state_id: state_id) do
    nil ->
      %UserAllowedState{}
      |> Ecto.Changeset.change(%{
        user_id: user_id,
        state_id: state_id,
        inserted_at: now,
        updated_at: now
      })
      |> Repo.insert!()

    _ ->
      :ok
  end
end

insert_allowed_constituency = fn user_id, constituency_id ->
  case Repo.get_by(UserAllowedConstituency, user_id: user_id, constituency_id: constituency_id) do
    nil ->
      %UserAllowedConstituency{}
      |> Ecto.Changeset.change(%{
        user_id: user_id,
        constituency_id: constituency_id,
        inserted_at: now,
        updated_at: now
      })
      |> Repo.insert!()

    _ ->
      :ok
  end
end

insert_allowed_campaign = fn user_id, campaign_id ->
  case Repo.get_by(UserAllowedCampaign, user_id: user_id, campaign_id: campaign_id) do
    nil ->
      %UserAllowedCampaign{}
      |> Ecto.Changeset.change(%{
        user_id: user_id,
        campaign_id: campaign_id,
        inserted_at: now,
        updated_at: now
      })
      |> Repo.insert!()

    _ ->
      :ok
  end
end

upsert_feature_permissions = fn user_id, permissions ->
  case Repo.get_by(UserFeaturePermission, user_id: user_id) do
    nil ->
      %UserFeaturePermission{}
      |> Ecto.Changeset.change(%{
        user_id: user_id,
        permissions: permissions,
        inserted_at: now,
        updated_at: now
      })
      |> Repo.insert!()

    record ->
      record
      |> Ecto.Changeset.change(%{
        permissions: permissions,
        updated_at: now
      })
      |> Repo.update!()
  end
end

# --------------------------------------------------
# 1. Create admin / owner
# --------------------------------------------------

admin =
  find_or_create_user.("admin@votegrid.in", "admin")

# --------------------------------------------------
# 2. Create 5 subadmin users
# --------------------------------------------------

subadmin1 = find_or_create_user.("subadmin1@votegrid.in", "subadmin")
subadmin2 = find_or_create_user.("subadmin2@votegrid.in", "subadmin")
subadmin3 = find_or_create_user.("subadmin3@votegrid.in", "subadmin")
subadmin4 = find_or_create_user.("subadmin4@votegrid.in", "subadmin")
subadmin5 = find_or_create_user.("subadmin5@votegrid.in", "subadmin")

# --------------------------------------------------
# 3. Create states
# --------------------------------------------------

tamil_nadu =
  find_or_create_state.(%{
    name: "Tamil Nadu",
    code: "TN",
    display_order: 1,
    is_active: true,
    user_id: admin.id
  })

pondicherry =
  find_or_create_state.(%{
    name: "Pondicherry",
    code: "PY",
    display_order: 2,
    is_active: true,
    user_id: admin.id
  })

# --------------------------------------------------
# 4. Create constituencies
# --------------------------------------------------

# Tamil Nadu constituencies
veerapandi =
  find_or_create_constituency.(%{
    name: "Veerapandi",
    code: "TN-VEERAPANDI",
    display_order: 1,
    is_active: true,
    state_id: tamil_nadu.id,
    user_id: admin.id
  })

salem_south =
  find_or_create_constituency.(%{
    name: "Salem South",
    code: "TN-SALEM-SOUTH",
    display_order: 2,
    is_active: true,
    state_id: tamil_nadu.id,
    user_id: admin.id
  })

coimbatore_south =
  find_or_create_constituency.(%{
    name: "Coimbatore South",
    code: "TN-COIMBATORE-SOUTH",
    display_order: 3,
    is_active: true,
    state_id: tamil_nadu.id,
    user_id: admin.id
  })

# Pondicherry constituencies
puducherry =
  find_or_create_constituency.(%{
    name: "Puducherry",
    code: "PY-PUDUCHERRY",
    display_order: 1,
    is_active: true,
    state_id: pondicherry.id,
    user_id: admin.id
  })

oulgaret =
  find_or_create_constituency.(%{
    name: "Oulgaret",
    code: "PY-OULGARET",
    display_order: 2,
    is_active: true,
    state_id: pondicherry.id,
    user_id: admin.id
  })

villianur =
  find_or_create_constituency.(%{
    name: "Villianur",
    code: "PY-VILLIANUR",
    display_order: 3,
    is_active: true,
    state_id: pondicherry.id,
    user_id: admin.id
  })

# --------------------------------------------------
# 5. Create campaigns
#    user_id = owner/admin
#    assigned_user_id = subadmin directly handling campaign
# --------------------------------------------------

start_at = ~U[2026-04-01 00:00:00Z]
end_at   = ~U[2026-12-31 23:59:59Z]

camp_veerapandi_1 =
  find_or_create_campaign.(%{
    name: "TN47 Veerapandi Campaign A",
    slug: "tn47-veerapandi-a",
    secret_code: "TN47A",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: veerapandi.id,
    user_id: admin.id,
    assigned_user_id: subadmin1.id
  })

camp_salem_south_1 =
  find_or_create_campaign.(%{
    name: "Salem South Campaign A",
    slug: "salem-south-a",
    secret_code: "SALA",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: salem_south.id,
    user_id: admin.id,
    assigned_user_id: subadmin2.id
  })

camp_coimbatore_south_1 =
  find_or_create_campaign.(%{
    name: "Coimbatore South Campaign A",
    slug: "coimbatore-south-a",
    secret_code: "COBA",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: coimbatore_south.id,
    user_id: admin.id,
    assigned_user_id: subadmin2.id
  })

camp_puducherry_1 =
  find_or_create_campaign.(%{
    name: "Puducherry Campaign A",
    slug: "puducherry-a",
    secret_code: "PUDA",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: puducherry.id,
    user_id: admin.id,
    assigned_user_id: subadmin3.id
  })

camp_oulgaret_1 =
  find_or_create_campaign.(%{
    name: "Oulgaret Campaign A",
    slug: "oulgaret-a",
    secret_code: "OULA",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: oulgaret.id,
    user_id: admin.id,
    assigned_user_id: subadmin4.id
  })

camp_villianur_1 =
  find_or_create_campaign.(%{
    name: "Villianur Campaign A",
    slug: "villianur-a",
    secret_code: "VILA",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: villianur.id,
    user_id: admin.id,
    assigned_user_id: subadmin4.id
  })

camp_cross_state_1 =
  find_or_create_campaign.(%{
    name: "Cross State Test Campaign",
    slug: "cross-state-test",
    secret_code: "CROSSTEST",
    is_active: true,
    starts_at: start_at,
    ends_at: end_at,
    constituency_id: veerapandi.id,
    user_id: admin.id,
    assigned_user_id: subadmin5.id
  })

# --------------------------------------------------
# 6. State restrictions
#    2 users -> Tamil Nadu
#    2 users -> Pondicherry
#    1 user -> both states
# --------------------------------------------------

# Tamil Nadu users
insert_allowed_state.(subadmin1.id, tamil_nadu.id)
insert_allowed_state.(subadmin2.id, tamil_nadu.id)

# Pondicherry users
insert_allowed_state.(subadmin3.id, pondicherry.id)
insert_allowed_state.(subadmin4.id, pondicherry.id)

# Mixed user
insert_allowed_state.(subadmin5.id, tamil_nadu.id)
insert_allowed_state.(subadmin5.id, pondicherry.id)

# --------------------------------------------------
# 7. Constituency restrictions
#    separate constituency and multiple constituency examples
# --------------------------------------------------

# subadmin1 -> only Veerapandi
insert_allowed_constituency.(subadmin1.id, veerapandi.id)

# subadmin2 -> multiple Tamil Nadu constituencies
insert_allowed_constituency.(subadmin2.id, salem_south.id)
insert_allowed_constituency.(subadmin2.id, coimbatore_south.id)

# subadmin3 -> only Puducherry
insert_allowed_constituency.(subadmin3.id, puducherry.id)

# subadmin4 -> multiple Pondicherry constituencies
insert_allowed_constituency.(subadmin4.id, oulgaret.id)
insert_allowed_constituency.(subadmin4.id, villianur.id)

# subadmin5 -> mixed state constituencies
insert_allowed_constituency.(subadmin5.id, veerapandi.id)
insert_allowed_constituency.(subadmin5.id, puducherry.id)

# --------------------------------------------------
# 8. Campaign restrictions
#    campaign restriction is mandatory for subadmin in your controller
# --------------------------------------------------

# subadmin1 -> only one campaign
insert_allowed_campaign.(subadmin1.id, camp_veerapandi_1.id)

# subadmin2 -> multiple campaigns
insert_allowed_campaign.(subadmin2.id, camp_salem_south_1.id)
insert_allowed_campaign.(subadmin2.id, camp_coimbatore_south_1.id)

# subadmin3 -> only one campaign
insert_allowed_campaign.(subadmin3.id, camp_puducherry_1.id)

# subadmin4 -> multiple campaigns
insert_allowed_campaign.(subadmin4.id, camp_oulgaret_1.id)
insert_allowed_campaign.(subadmin4.id, camp_villianur_1.id)

# subadmin5 -> mixed test campaigns
insert_allowed_campaign.(subadmin5.id, camp_cross_state_1.id)
insert_allowed_campaign.(subadmin5.id, camp_puducherry_1.id)

# --------------------------------------------------
# 9. Feature permissions
# --------------------------------------------------

restricted_permissions = %{
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

upsert_feature_permissions.(subadmin1.id, restricted_permissions)
upsert_feature_permissions.(subadmin2.id, restricted_permissions)
upsert_feature_permissions.(subadmin3.id, restricted_permissions)
upsert_feature_permissions.(subadmin4.id, restricted_permissions)
upsert_feature_permissions.(subadmin5.id, restricted_permissions)

IO.puts("Seed completed successfully.")