defmodule ElectionPollWeb.AdminRestrictionController do
  use ElectionPollWeb, :controller

  alias ElectionPoll.Accounts
  alias ElectionPoll.Elections

  def index(conn, params) do
    users = Accounts.list_non_admin_users()

    selected_user_id =
      case params["user_id"] do
        nil ->
          case users do
            [first | _] -> first.id
            [] -> nil
          end

        id ->
          String.to_integer(id)
      end

    selected_user =
      if selected_user_id do
        Accounts.get_user!(selected_user_id)
      else
        nil
      end

    restrictions =
      if selected_user do
        Accounts.get_user_restrictions(selected_user.id)
      else
        %{
          campaign_ids: [],
          state_ids: [],
          constituency_ids: [],
          feature_permissions: nil
        }
      end

    render(conn, :index,
      users: users,
      selected_user: selected_user,
      restrictions: restrictions,
      campaigns: Elections.list_all_campaigns(),
      states: Elections.list_all_states(),
      constituencies: Elections.list_all_constituencies(),
      booths: Elections.list_all_booths()
    )
  end

  def save(conn, %{"user_id" => user_id} = params) do
    user = Accounts.get_user!(String.to_integer(user_id))

    if user.role == "admin" do
      conn
      |> put_flash(:error, "Restrictions cannot be applied to admin users.")
      |> redirect(to: ~p"/admin/user-restrictions")
    else
      case Accounts.save_user_restrictions(user.id, params) do
        {:ok, _} ->
          conn
          |> put_flash(:info, "Restrictions updated successfully.")
          |> redirect(to: ~p"/admin/user-restrictions?user_id=#{user.id}")

        {:error, _reason} ->
          conn
          |> put_flash(:error, "Unable to update restrictions.")
          |> redirect(to: ~p"/admin/user-restrictions?user_id=#{user.id}")
      end
    end
  end
end