defmodule ElectionPoll.ElectionsTest do
  use ElectionPoll.DataCase

  alias ElectionPoll.Elections

  describe "states" do
    alias ElectionPoll.Elections.State

    import ElectionPoll.AccountsFixtures, only: [user_scope_fixture: 0]
    import ElectionPoll.ElectionsFixtures

    @invalid_attrs %{code: nil, name: nil, display_order: nil, is_active: nil}

    test "list_states/1 returns all scoped states" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      state = state_fixture(scope)
      other_state = state_fixture(other_scope)
      assert Elections.list_states(scope) == [state]
      assert Elections.list_states(other_scope) == [other_state]
    end

    test "get_state!/2 returns the state with given id" do
      scope = user_scope_fixture()
      state = state_fixture(scope)
      other_scope = user_scope_fixture()
      assert Elections.get_state!(scope, state.id) == state
      assert_raise Ecto.NoResultsError, fn -> Elections.get_state!(other_scope, state.id) end
    end

    test "create_state/2 with valid data creates a state" do
      valid_attrs = %{code: "some code", name: "some name", display_order: 42, is_active: true}
      scope = user_scope_fixture()

      assert {:ok, %State{} = state} = Elections.create_state(scope, valid_attrs)
      assert state.code == "some code"
      assert state.name == "some name"
      assert state.display_order == 42
      assert state.is_active == true
      assert state.user_id == scope.user.id
    end

    test "create_state/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Elections.create_state(scope, @invalid_attrs)
    end

    test "update_state/3 with valid data updates the state" do
      scope = user_scope_fixture()
      state = state_fixture(scope)
      update_attrs = %{code: "some updated code", name: "some updated name", display_order: 43, is_active: false}

      assert {:ok, %State{} = state} = Elections.update_state(scope, state, update_attrs)
      assert state.code == "some updated code"
      assert state.name == "some updated name"
      assert state.display_order == 43
      assert state.is_active == false
    end

    test "update_state/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      state = state_fixture(scope)

      assert_raise MatchError, fn ->
        Elections.update_state(other_scope, state, %{})
      end
    end

    test "update_state/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      state = state_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Elections.update_state(scope, state, @invalid_attrs)
      assert state == Elections.get_state!(scope, state.id)
    end

    test "delete_state/2 deletes the state" do
      scope = user_scope_fixture()
      state = state_fixture(scope)
      assert {:ok, %State{}} = Elections.delete_state(scope, state)
      assert_raise Ecto.NoResultsError, fn -> Elections.get_state!(scope, state.id) end
    end

    test "delete_state/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      state = state_fixture(scope)
      assert_raise MatchError, fn -> Elections.delete_state(other_scope, state) end
    end

    test "change_state/2 returns a state changeset" do
      scope = user_scope_fixture()
      state = state_fixture(scope)
      assert %Ecto.Changeset{} = Elections.change_state(scope, state)
    end
  end

  describe "constituencies" do
    alias ElectionPoll.Elections.Constituency

    import ElectionPoll.AccountsFixtures, only: [user_scope_fixture: 0]
    import ElectionPoll.ElectionsFixtures

    @invalid_attrs %{code: nil, name: nil, display_order: nil, is_active: nil}

    test "list_constituencies/1 returns all scoped constituencies" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      constituency = constituency_fixture(scope)
      other_constituency = constituency_fixture(other_scope)
      assert Elections.list_constituencies(scope) == [constituency]
      assert Elections.list_constituencies(other_scope) == [other_constituency]
    end

    test "get_constituency!/2 returns the constituency with given id" do
      scope = user_scope_fixture()
      constituency = constituency_fixture(scope)
      other_scope = user_scope_fixture()
      assert Elections.get_constituency!(scope, constituency.id) == constituency
      assert_raise Ecto.NoResultsError, fn -> Elections.get_constituency!(other_scope, constituency.id) end
    end

    test "create_constituency/2 with valid data creates a constituency" do
      valid_attrs = %{code: "some code", name: "some name", display_order: 42, is_active: true}
      scope = user_scope_fixture()

      assert {:ok, %Constituency{} = constituency} = Elections.create_constituency(scope, valid_attrs)
      assert constituency.code == "some code"
      assert constituency.name == "some name"
      assert constituency.display_order == 42
      assert constituency.is_active == true
      assert constituency.user_id == scope.user.id
    end

    test "create_constituency/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Elections.create_constituency(scope, @invalid_attrs)
    end

    test "update_constituency/3 with valid data updates the constituency" do
      scope = user_scope_fixture()
      constituency = constituency_fixture(scope)
      update_attrs = %{code: "some updated code", name: "some updated name", display_order: 43, is_active: false}

      assert {:ok, %Constituency{} = constituency} = Elections.update_constituency(scope, constituency, update_attrs)
      assert constituency.code == "some updated code"
      assert constituency.name == "some updated name"
      assert constituency.display_order == 43
      assert constituency.is_active == false
    end

    test "update_constituency/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      constituency = constituency_fixture(scope)

      assert_raise MatchError, fn ->
        Elections.update_constituency(other_scope, constituency, %{})
      end
    end

    test "update_constituency/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      constituency = constituency_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Elections.update_constituency(scope, constituency, @invalid_attrs)
      assert constituency == Elections.get_constituency!(scope, constituency.id)
    end

    test "delete_constituency/2 deletes the constituency" do
      scope = user_scope_fixture()
      constituency = constituency_fixture(scope)
      assert {:ok, %Constituency{}} = Elections.delete_constituency(scope, constituency)
      assert_raise Ecto.NoResultsError, fn -> Elections.get_constituency!(scope, constituency.id) end
    end

    test "delete_constituency/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      constituency = constituency_fixture(scope)
      assert_raise MatchError, fn -> Elections.delete_constituency(other_scope, constituency) end
    end

    test "change_constituency/2 returns a constituency changeset" do
      scope = user_scope_fixture()
      constituency = constituency_fixture(scope)
      assert %Ecto.Changeset{} = Elections.change_constituency(scope, constituency)
    end
  end

  describe "candidates" do
    alias ElectionPoll.Elections.Candidate

    import ElectionPoll.AccountsFixtures, only: [user_scope_fixture: 0]
    import ElectionPoll.ElectionsFixtures

    @invalid_attrs %{color: nil, candidate_name: nil, party_full_name: nil, abbreviation: nil, alliance: nil, display_order: nil, symbol_image: nil, symbol_name: nil, is_active: nil}

    test "list_candidates/1 returns all scoped candidates" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      candidate = candidate_fixture(scope)
      other_candidate = candidate_fixture(other_scope)
      assert Elections.list_candidates(scope) == [candidate]
      assert Elections.list_candidates(other_scope) == [other_candidate]
    end

    test "get_candidate!/2 returns the candidate with given id" do
      scope = user_scope_fixture()
      candidate = candidate_fixture(scope)
      other_scope = user_scope_fixture()
      assert Elections.get_candidate!(scope, candidate.id) == candidate
      assert_raise Ecto.NoResultsError, fn -> Elections.get_candidate!(other_scope, candidate.id) end
    end

    test "create_candidate/2 with valid data creates a candidate" do
      valid_attrs = %{color: "some color", candidate_name: "some candidate_name", party_full_name: "some party_full_name", abbreviation: "some abbreviation", alliance: "some alliance", display_order: 42, symbol_image: "some symbol_image", symbol_name: "some symbol_name", is_active: true}
      scope = user_scope_fixture()

      assert {:ok, %Candidate{} = candidate} = Elections.create_candidate(scope, valid_attrs)
      assert candidate.color == "some color"
      assert candidate.candidate_name == "some candidate_name"
      assert candidate.party_full_name == "some party_full_name"
      assert candidate.abbreviation == "some abbreviation"
      assert candidate.alliance == "some alliance"
      assert candidate.display_order == 42
      assert candidate.symbol_image == "some symbol_image"
      assert candidate.symbol_name == "some symbol_name"
      assert candidate.is_active == true
      assert candidate.user_id == scope.user.id
    end

    test "create_candidate/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Elections.create_candidate(scope, @invalid_attrs)
    end

    test "update_candidate/3 with valid data updates the candidate" do
      scope = user_scope_fixture()
      candidate = candidate_fixture(scope)
      update_attrs = %{color: "some updated color", candidate_name: "some updated candidate_name", party_full_name: "some updated party_full_name", abbreviation: "some updated abbreviation", alliance: "some updated alliance", display_order: 43, symbol_image: "some updated symbol_image", symbol_name: "some updated symbol_name", is_active: false}

      assert {:ok, %Candidate{} = candidate} = Elections.update_candidate(scope, candidate, update_attrs)
      assert candidate.color == "some updated color"
      assert candidate.candidate_name == "some updated candidate_name"
      assert candidate.party_full_name == "some updated party_full_name"
      assert candidate.abbreviation == "some updated abbreviation"
      assert candidate.alliance == "some updated alliance"
      assert candidate.display_order == 43
      assert candidate.symbol_image == "some updated symbol_image"
      assert candidate.symbol_name == "some updated symbol_name"
      assert candidate.is_active == false
    end

    test "update_candidate/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      candidate = candidate_fixture(scope)

      assert_raise MatchError, fn ->
        Elections.update_candidate(other_scope, candidate, %{})
      end
    end

    test "update_candidate/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      candidate = candidate_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Elections.update_candidate(scope, candidate, @invalid_attrs)
      assert candidate == Elections.get_candidate!(scope, candidate.id)
    end

    test "delete_candidate/2 deletes the candidate" do
      scope = user_scope_fixture()
      candidate = candidate_fixture(scope)
      assert {:ok, %Candidate{}} = Elections.delete_candidate(scope, candidate)
      assert_raise Ecto.NoResultsError, fn -> Elections.get_candidate!(scope, candidate.id) end
    end

    test "delete_candidate/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      candidate = candidate_fixture(scope)
      assert_raise MatchError, fn -> Elections.delete_candidate(other_scope, candidate) end
    end

    test "change_candidate/2 returns a candidate changeset" do
      scope = user_scope_fixture()
      candidate = candidate_fixture(scope)
      assert %Ecto.Changeset{} = Elections.change_candidate(scope, candidate)
    end
  end

  describe "campaigns" do
    alias ElectionPoll.Elections.Campaign

    import ElectionPoll.AccountsFixtures, only: [user_scope_fixture: 0]
    import ElectionPoll.ElectionsFixtures

    @invalid_attrs %{name: nil, slug: nil, secret_code: nil, is_active: nil, starts_at: nil, ends_at: nil}

    test "list_campaigns/1 returns all scoped campaigns" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      campaign = campaign_fixture(scope)
      other_campaign = campaign_fixture(other_scope)
      assert Elections.list_campaigns(scope) == [campaign]
      assert Elections.list_campaigns(other_scope) == [other_campaign]
    end

    test "get_campaign!/2 returns the campaign with given id" do
      scope = user_scope_fixture()
      campaign = campaign_fixture(scope)
      other_scope = user_scope_fixture()
      assert Elections.get_campaign!(scope, campaign.id) == campaign
      assert_raise Ecto.NoResultsError, fn -> Elections.get_campaign!(other_scope, campaign.id) end
    end

    test "create_campaign/2 with valid data creates a campaign" do
      valid_attrs = %{name: "some name", slug: "some slug", secret_code: "some secret_code", is_active: true, starts_at: ~U[2026-04-09 17:14:00Z], ends_at: ~U[2026-04-09 17:14:00Z]}
      scope = user_scope_fixture()

      assert {:ok, %Campaign{} = campaign} = Elections.create_campaign(scope, valid_attrs)
      assert campaign.name == "some name"
      assert campaign.slug == "some slug"
      assert campaign.secret_code == "some secret_code"
      assert campaign.is_active == true
      assert campaign.starts_at == ~U[2026-04-09 17:14:00Z]
      assert campaign.ends_at == ~U[2026-04-09 17:14:00Z]
      assert campaign.user_id == scope.user.id
    end

    test "create_campaign/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Elections.create_campaign(scope, @invalid_attrs)
    end

    test "update_campaign/3 with valid data updates the campaign" do
      scope = user_scope_fixture()
      campaign = campaign_fixture(scope)
      update_attrs = %{name: "some updated name", slug: "some updated slug", secret_code: "some updated secret_code", is_active: false, starts_at: ~U[2026-04-10 17:14:00Z], ends_at: ~U[2026-04-10 17:14:00Z]}

      assert {:ok, %Campaign{} = campaign} = Elections.update_campaign(scope, campaign, update_attrs)
      assert campaign.name == "some updated name"
      assert campaign.slug == "some updated slug"
      assert campaign.secret_code == "some updated secret_code"
      assert campaign.is_active == false
      assert campaign.starts_at == ~U[2026-04-10 17:14:00Z]
      assert campaign.ends_at == ~U[2026-04-10 17:14:00Z]
    end

    test "update_campaign/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      campaign = campaign_fixture(scope)

      assert_raise MatchError, fn ->
        Elections.update_campaign(other_scope, campaign, %{})
      end
    end

    test "update_campaign/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      campaign = campaign_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Elections.update_campaign(scope, campaign, @invalid_attrs)
      assert campaign == Elections.get_campaign!(scope, campaign.id)
    end

    test "delete_campaign/2 deletes the campaign" do
      scope = user_scope_fixture()
      campaign = campaign_fixture(scope)
      assert {:ok, %Campaign{}} = Elections.delete_campaign(scope, campaign)
      assert_raise Ecto.NoResultsError, fn -> Elections.get_campaign!(scope, campaign.id) end
    end

    test "delete_campaign/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      campaign = campaign_fixture(scope)
      assert_raise MatchError, fn -> Elections.delete_campaign(other_scope, campaign) end
    end

    test "change_campaign/2 returns a campaign changeset" do
      scope = user_scope_fixture()
      campaign = campaign_fixture(scope)
      assert %Ecto.Changeset{} = Elections.change_campaign(scope, campaign)
    end
  end
end
