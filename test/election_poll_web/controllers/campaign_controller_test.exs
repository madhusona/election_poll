defmodule ElectionPollWeb.CampaignControllerTest do
  use ElectionPollWeb.ConnCase

  import ElectionPoll.ElectionsFixtures

  @create_attrs %{name: "some name", slug: "some slug", secret_code: "some secret_code", is_active: true, starts_at: ~U[2026-04-09 17:14:00Z], ends_at: ~U[2026-04-09 17:14:00Z]}
  @update_attrs %{name: "some updated name", slug: "some updated slug", secret_code: "some updated secret_code", is_active: false, starts_at: ~U[2026-04-10 17:14:00Z], ends_at: ~U[2026-04-10 17:14:00Z]}
  @invalid_attrs %{name: nil, slug: nil, secret_code: nil, is_active: nil, starts_at: nil, ends_at: nil}

  setup :register_and_log_in_user

  describe "index" do
    test "lists all campaigns", %{conn: conn} do
      conn = get(conn, ~p"/campaigns")
      assert html_response(conn, 200) =~ "Listing Campaigns"
    end
  end

  describe "new campaign" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/campaigns/new")
      assert html_response(conn, 200) =~ "New Campaign"
    end
  end

  describe "create campaign" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/campaigns", campaign: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/campaigns/#{id}"

      conn = get(conn, ~p"/campaigns/#{id}")
      assert html_response(conn, 200) =~ "Campaign #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/campaigns", campaign: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Campaign"
    end
  end

  describe "edit campaign" do
    setup [:create_campaign]

    test "renders form for editing chosen campaign", %{conn: conn, campaign: campaign} do
      conn = get(conn, ~p"/campaigns/#{campaign}/edit")
      assert html_response(conn, 200) =~ "Edit Campaign"
    end
  end

  describe "update campaign" do
    setup [:create_campaign]

    test "redirects when data is valid", %{conn: conn, campaign: campaign} do
      conn = put(conn, ~p"/campaigns/#{campaign}", campaign: @update_attrs)
      assert redirected_to(conn) == ~p"/campaigns/#{campaign}"

      conn = get(conn, ~p"/campaigns/#{campaign}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, campaign: campaign} do
      conn = put(conn, ~p"/campaigns/#{campaign}", campaign: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Campaign"
    end
  end

  describe "delete campaign" do
    setup [:create_campaign]

    test "deletes chosen campaign", %{conn: conn, campaign: campaign} do
      conn = delete(conn, ~p"/campaigns/#{campaign}")
      assert redirected_to(conn) == ~p"/campaigns"

      assert_error_sent 404, fn ->
        get(conn, ~p"/campaigns/#{campaign}")
      end
    end
  end

  defp create_campaign(%{scope: scope}) do
    campaign = campaign_fixture(scope)

    %{campaign: campaign}
  end
end
