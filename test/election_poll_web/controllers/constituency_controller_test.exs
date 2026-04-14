defmodule ElectionPollWeb.ConstituencyControllerTest do
  use ElectionPollWeb.ConnCase

  import ElectionPoll.ElectionsFixtures

  @create_attrs %{code: "some code", name: "some name", display_order: 42, is_active: true}
  @update_attrs %{code: "some updated code", name: "some updated name", display_order: 43, is_active: false}
  @invalid_attrs %{code: nil, name: nil, display_order: nil, is_active: nil}

  setup :register_and_log_in_user

  describe "index" do
    test "lists all constituencies", %{conn: conn} do
      conn = get(conn, ~p"/constituencies")
      assert html_response(conn, 200) =~ "Listing Constituencies"
    end
  end

  describe "new constituency" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/constituencies/new")
      assert html_response(conn, 200) =~ "New Constituency"
    end
  end

  describe "create constituency" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/constituencies", constituency: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/constituencies/#{id}"

      conn = get(conn, ~p"/constituencies/#{id}")
      assert html_response(conn, 200) =~ "Constituency #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/constituencies", constituency: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Constituency"
    end
  end

  describe "edit constituency" do
    setup [:create_constituency]

    test "renders form for editing chosen constituency", %{conn: conn, constituency: constituency} do
      conn = get(conn, ~p"/constituencies/#{constituency}/edit")
      assert html_response(conn, 200) =~ "Edit Constituency"
    end
  end

  describe "update constituency" do
    setup [:create_constituency]

    test "redirects when data is valid", %{conn: conn, constituency: constituency} do
      conn = put(conn, ~p"/constituencies/#{constituency}", constituency: @update_attrs)
      assert redirected_to(conn) == ~p"/constituencies/#{constituency}"

      conn = get(conn, ~p"/constituencies/#{constituency}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, constituency: constituency} do
      conn = put(conn, ~p"/constituencies/#{constituency}", constituency: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Constituency"
    end
  end

  describe "delete constituency" do
    setup [:create_constituency]

    test "deletes chosen constituency", %{conn: conn, constituency: constituency} do
      conn = delete(conn, ~p"/constituencies/#{constituency}")
      assert redirected_to(conn) == ~p"/constituencies"

      assert_error_sent 404, fn ->
        get(conn, ~p"/constituencies/#{constituency}")
      end
    end
  end

  defp create_constituency(%{scope: scope}) do
    constituency = constituency_fixture(scope)

    %{constituency: constituency}
  end
end
