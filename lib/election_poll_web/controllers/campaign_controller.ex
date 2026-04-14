defmodule ElectionPollWeb.CampaignController do
  use ElectionPollWeb, :controller

  alias ElectionPoll.Elections
  alias ElectionPoll.Elections.Campaign
  alias ElectionPoll.Accounts

  def index(conn, _params) do
    scope = conn.assigns.current_scope
    campaigns = Elections.list_campaigns(scope)
    render(conn, :index, campaigns: campaigns)
  end

  def new(conn, _params) do
    scope = conn.assigns.current_scope
    changeset = Elections.change_campaign(scope, %Campaign{})
    constituencies = Elections.list_constituencies()
    subadmins = Accounts.list_subadmins()

    render(conn, :new,
      changeset: changeset,
      constituencies: constituencies,
      subadmins: subadmins
    )
  end

  def create(conn, %{"campaign" => campaign_params}) do
    scope = conn.assigns.current_scope

    case Elections.create_campaign(scope, campaign_params) do
      {:ok, campaign} ->
        conn
        |> put_flash(:info, "Campaign created successfully.")
        |> redirect(to: ~p"/campaigns/#{campaign}")

      {:error, %Ecto.Changeset{} = changeset} ->
        constituencies = Elections.list_constituencies()
        subadmins = Accounts.list_subadmins()

        render(conn, :new,
          changeset: changeset,
          constituencies: constituencies,
          subadmins: subadmins
        )
    end
  end

  def show(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    campaign = Elections.get_campaign!(scope, id)
    render(conn, :show, campaign: campaign)
  end

  def edit(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    campaign = Elections.get_campaign!(scope, id)
    changeset = Elections.change_campaign(scope, campaign)
    constituencies = Elections.list_constituencies()
    subadmins = Accounts.list_subadmins()

    render(conn, :edit,
      campaign: campaign,
      changeset: changeset,
      constituencies: constituencies,
      subadmins: subadmins
    )
  end

  def update(conn, %{"id" => id, "campaign" => campaign_params}) do
    scope = conn.assigns.current_scope
    campaign = Elections.get_campaign!(scope, id)

    case Elections.update_campaign(scope, campaign, campaign_params) do
      {:ok, campaign} ->
        conn
        |> put_flash(:info, "Campaign updated successfully.")
        |> redirect(to: ~p"/campaigns/#{campaign}")

      {:error, %Ecto.Changeset{} = changeset} ->
        constituencies = Elections.list_constituencies()
        subadmins = Accounts.list_subadmins()

        render(conn, :edit,
          campaign: campaign,
          changeset: changeset,
          constituencies: constituencies,
          subadmins: subadmins
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    campaign = Elections.get_campaign!(scope, id)

    case Elections.delete_campaign(scope, campaign) do
      {:ok, _campaign} ->
        conn
        |> put_flash(:info, "Campaign deleted successfully.")
        |> redirect(to: ~p"/campaigns")

      {:error, _reason} ->
        conn
        |> put_flash(:error, "Unable to delete campaign.")
        |> redirect(to: ~p"/campaigns")
    end
  end
end