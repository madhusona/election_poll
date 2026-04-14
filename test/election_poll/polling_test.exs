defmodule ElectionPoll.PollingTest do
  use ElectionPoll.DataCase

  alias ElectionPoll.Polling

  describe "responses" do
    alias ElectionPoll.Polling.Response

    import ElectionPoll.AccountsFixtures, only: [user_scope_fixture: 0]
    import ElectionPoll.PollingFixtures

    @invalid_attrs %{voter_name: nil, mobile: nil, secret_code: nil, selfie_path: nil, latitude: nil, longitude: nil, submitted_at: nil}

    test "list_responses/1 returns all scoped responses" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      response = response_fixture(scope)
      other_response = response_fixture(other_scope)
      assert Polling.list_responses(scope) == [response]
      assert Polling.list_responses(other_scope) == [other_response]
    end

    test "get_response!/2 returns the response with given id" do
      scope = user_scope_fixture()
      response = response_fixture(scope)
      other_scope = user_scope_fixture()
      assert Polling.get_response!(scope, response.id) == response
      assert_raise Ecto.NoResultsError, fn -> Polling.get_response!(other_scope, response.id) end
    end

    test "create_response/2 with valid data creates a response" do
      valid_attrs = %{voter_name: "some voter_name", mobile: "some mobile", secret_code: "some secret_code", selfie_path: "some selfie_path", latitude: 120.5, longitude: 120.5, submitted_at: ~U[2026-04-09 17:13:00Z]}
      scope = user_scope_fixture()

      assert {:ok, %Response{} = response} = Polling.create_response(scope, valid_attrs)
      assert response.voter_name == "some voter_name"
      assert response.mobile == "some mobile"
      assert response.secret_code == "some secret_code"
      assert response.selfie_path == "some selfie_path"
      assert response.latitude == 120.5
      assert response.longitude == 120.5
      assert response.submitted_at == ~U[2026-04-09 17:13:00Z]
      assert response.user_id == scope.user.id
    end

    test "create_response/2 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      assert {:error, %Ecto.Changeset{}} = Polling.create_response(scope, @invalid_attrs)
    end

    test "update_response/3 with valid data updates the response" do
      scope = user_scope_fixture()
      response = response_fixture(scope)
      update_attrs = %{voter_name: "some updated voter_name", mobile: "some updated mobile", secret_code: "some updated secret_code", selfie_path: "some updated selfie_path", latitude: 456.7, longitude: 456.7, submitted_at: ~U[2026-04-10 17:13:00Z]}

      assert {:ok, %Response{} = response} = Polling.update_response(scope, response, update_attrs)
      assert response.voter_name == "some updated voter_name"
      assert response.mobile == "some updated mobile"
      assert response.secret_code == "some updated secret_code"
      assert response.selfie_path == "some updated selfie_path"
      assert response.latitude == 456.7
      assert response.longitude == 456.7
      assert response.submitted_at == ~U[2026-04-10 17:13:00Z]
    end

    test "update_response/3 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      response = response_fixture(scope)

      assert_raise MatchError, fn ->
        Polling.update_response(other_scope, response, %{})
      end
    end

    test "update_response/3 with invalid data returns error changeset" do
      scope = user_scope_fixture()
      response = response_fixture(scope)
      assert {:error, %Ecto.Changeset{}} = Polling.update_response(scope, response, @invalid_attrs)
      assert response == Polling.get_response!(scope, response.id)
    end

    test "delete_response/2 deletes the response" do
      scope = user_scope_fixture()
      response = response_fixture(scope)
      assert {:ok, %Response{}} = Polling.delete_response(scope, response)
      assert_raise Ecto.NoResultsError, fn -> Polling.get_response!(scope, response.id) end
    end

    test "delete_response/2 with invalid scope raises" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      response = response_fixture(scope)
      assert_raise MatchError, fn -> Polling.delete_response(other_scope, response) end
    end

    test "change_response/2 returns a response changeset" do
      scope = user_scope_fixture()
      response = response_fixture(scope)
      assert %Ecto.Changeset{} = Polling.change_response(scope, response)
    end
  end
end
