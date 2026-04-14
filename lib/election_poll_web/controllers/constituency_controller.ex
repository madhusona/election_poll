defmodule ElectionPollWeb.ConstituencyController do
  use ElectionPollWeb, :controller

  alias ElectionPoll.Elections
  alias ElectionPoll.Elections.Constituency

  def index(conn, _params) do
    constituencies = Elections.list_constituencies(conn.assigns.current_scope)
    render(conn, :index, constituencies: constituencies)
  end

  def new(conn, _params) do
    changeset =
      Elections.change_constituency(conn.assigns.current_scope, %Constituency{
        user_id: conn.assigns.current_scope.user.id
      })

    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"constituency" => constituency_params}) do
    case Elections.create_constituency(conn.assigns.current_scope, constituency_params) do
      {:ok, constituency} ->
        conn
        |> put_flash(:info, "Constituency created successfully.")
        |> redirect(to: ~p"/constituencies/#{constituency}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    constituency = Elections.get_constituency!(conn.assigns.current_scope, id)
    render(conn, :show, constituency: constituency)
  end

  def edit(conn, %{"id" => id}) do
    constituency = Elections.get_constituency!(conn.assigns.current_scope, id)
    changeset = Elections.change_constituency(conn.assigns.current_scope, constituency)
    render(conn, :edit, constituency: constituency, changeset: changeset)
  end

  def update(conn, %{"id" => id, "constituency" => constituency_params}) do
    constituency = Elections.get_constituency!(conn.assigns.current_scope, id)

    case Elections.update_constituency(conn.assigns.current_scope, constituency, constituency_params) do
      {:ok, constituency} ->
        conn
        |> put_flash(:info, "Constituency updated successfully.")
        |> redirect(to: ~p"/constituencies/#{constituency}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, constituency: constituency, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    constituency = Elections.get_constituency!(conn.assigns.current_scope, id)
    {:ok, _constituency} = Elections.delete_constituency(conn.assigns.current_scope, constituency)

    conn
    |> put_flash(:info, "Constituency deleted successfully.")
    |> redirect(to: ~p"/constituencies")
  end
end
