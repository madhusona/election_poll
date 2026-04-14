defmodule ElectionPollWeb.CandidateControllerTest do
  use ElectionPollWeb.ConnCase

  import ElectionPoll.ElectionsFixtures

  @create_attrs %{color: "some color", candidate_name: "some candidate_name", party_full_name: "some party_full_name", abbreviation: "some abbreviation", alliance: "some alliance", display_order: 42, symbol_image: "some symbol_image", symbol_name: "some symbol_name", is_active: true}
  @update_attrs %{color: "some updated color", candidate_name: "some updated candidate_name", party_full_name: "some updated party_full_name", abbreviation: "some updated abbreviation", alliance: "some updated alliance", display_order: 43, symbol_image: "some updated symbol_image", symbol_name: "some updated symbol_name", is_active: false}
  @invalid_attrs %{color: nil, candidate_name: nil, party_full_name: nil, abbreviation: nil, alliance: nil, display_order: nil, symbol_image: nil, symbol_name: nil, is_active: nil}

  setup :register_and_log_in_user

  describe "index" do
    test "lists all candidates", %{conn: conn} do
      conn = get(conn, ~p"/candidates")
      assert html_response(conn, 200) =~ "Listing Candidates"
    end
  end

  describe "new candidate" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/candidates/new")
      assert html_response(conn, 200) =~ "New Candidate"
    end
  end

  describe "create candidate" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/candidates", candidate: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/candidates/#{id}"

      conn = get(conn, ~p"/candidates/#{id}")
      assert html_response(conn, 200) =~ "Candidate #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/candidates", candidate: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Candidate"
    end
  end

  describe "edit candidate" do
    setup [:create_candidate]

    test "renders form for editing chosen candidate", %{conn: conn, candidate: candidate} do
      conn = get(conn, ~p"/candidates/#{candidate}/edit")
      assert html_response(conn, 200) =~ "Edit Candidate"
    end
  end

  describe "update candidate" do
    setup [:create_candidate]

    test "redirects when data is valid", %{conn: conn, candidate: candidate} do
      conn = put(conn, ~p"/candidates/#{candidate}", candidate: @update_attrs)
      assert redirected_to(conn) == ~p"/candidates/#{candidate}"

      conn = get(conn, ~p"/candidates/#{candidate}")
      assert html_response(conn, 200) =~ "some updated candidate_name"
    end

    test "renders errors when data is invalid", %{conn: conn, candidate: candidate} do
      conn = put(conn, ~p"/candidates/#{candidate}", candidate: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Candidate"
    end
  end

  describe "delete candidate" do
    setup [:create_candidate]

    test "deletes chosen candidate", %{conn: conn, candidate: candidate} do
      conn = delete(conn, ~p"/candidates/#{candidate}")
      assert redirected_to(conn) == ~p"/candidates"

      assert_error_sent 404, fn ->
        get(conn, ~p"/candidates/#{candidate}")
      end
    end
  end

  defp create_candidate(%{scope: scope}) do
    candidate = candidate_fixture(scope)

    %{candidate: candidate}
  end
end
