defmodule ElectionPollWeb.StateControllerTest do
  use ElectionPollWeb.ConnCase

  import ElectionPoll.ElectionsFixtures

  @create_attrs %{code: "some code", name: "some name", display_order: 42, is_active: true}
  @update_attrs %{code: "some updated code", name: "some updated name", display_order: 43, is_active: false}
  @invalid_attrs %{code: nil, name: nil, display_order: nil, is_active: nil}

  setup :register_and_log_in_user

  describe "index" do
    test "lists all states", %{conn: conn} do
      conn = get(conn, ~p"/states")
      assert html_response(conn, 200) =~ "Listing States"
    end
  end

  describe "new state" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/states/new")
      assert html_response(conn, 200) =~ "New State"
    end
  end

  describe "create state" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/states", state: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/states/#{id}"

      conn = get(conn, ~p"/states/#{id}")
      assert html_response(conn, 200) =~ "State #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/states", state: @invalid_attrs)
      assert html_response(conn, 200) =~ "New State"
    end
  end

  describe "edit state" do
    setup [:create_state]

    test "renders form for editing chosen state", %{conn: conn, state: state} do
      conn = get(conn, ~p"/states/#{state}/edit")
      assert html_response(conn, 200) =~ "Edit State"
    end
  end

  describe "update state" do
    setup [:create_state]

    test "redirects when data is valid", %{conn: conn, state: state} do
      conn = put(conn, ~p"/states/#{state}", state: @update_attrs)
      assert redirected_to(conn) == ~p"/states/#{state}"

      conn = get(conn, ~p"/states/#{state}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, state: state} do
      conn = put(conn, ~p"/states/#{state}", state: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit State"
    end
  end

  describe "delete state" do
    setup [:create_state]

    test "deletes chosen state", %{conn: conn, state: state} do
      conn = delete(conn, ~p"/states/#{state}")
      assert redirected_to(conn) == ~p"/states"

      assert_error_sent 404, fn ->
        get(conn, ~p"/states/#{state}")
      end
    end
  end

  defp create_state(%{scope: scope}) do
    state = state_fixture(scope)

    %{state: state}
  end
end
