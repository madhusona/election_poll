defmodule ElectionPollWeb.BoothController do
  use ElectionPollWeb, :controller

  alias ElectionPoll.Elections
  alias ElectionPoll.Elections.Booth

  def index(conn, _params) do
    scope = conn.assigns.current_scope
    booths = Elections.list_booths(scope)
    render(conn, :index, booths: booths)
  end

  def new(conn, _params) do
    scope = conn.assigns.current_scope
    changeset = Elections.change_booth(scope, %Booth{})
    constituencies = Elections.list_constituencies(scope)
    render(conn, :new, changeset: changeset, constituencies: constituencies)
  end

  def create(conn, %{"booth" => booth_params}) do
    scope = conn.assigns.current_scope

    case Elections.create_booth(scope, booth_params) do
      {:ok, booth} ->
        conn
        |> put_flash(:info, "Booth created successfully.")
        |> redirect(to: ~p"/booths/#{booth}")

      {:error, changeset} ->
        constituencies = Elections.list_constituencies(scope)
        render(conn, :new, changeset: changeset, constituencies: constituencies)
    end
  end

  def show(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    booth = Elections.get_booth!(scope, id)
    render(conn, :show, booth: booth)
  end

  def edit(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    booth = Elections.get_booth!(scope, id)
    changeset = Elections.change_booth(scope, booth)
    constituencies = Elections.list_constituencies(scope)
    render(conn, :edit, booth: booth, changeset: changeset, constituencies: constituencies)
  end

  def update(conn, %{"id" => id, "booth" => booth_params}) do
    scope = conn.assigns.current_scope
    booth = Elections.get_booth!(scope, id)

    case Elections.update_booth(scope, booth, booth_params) do
      {:ok, booth} ->
        conn
        |> put_flash(:info, "Booth updated successfully.")
        |> redirect(to: ~p"/booths/#{booth}")

      {:error, changeset} ->
        constituencies = Elections.list_constituencies(scope)
        render(conn, :edit, booth: booth, changeset: changeset, constituencies: constituencies)
    end
  end

  def delete(conn, %{"id" => id}) do
    scope = conn.assigns.current_scope
    booth = Elections.get_booth!(scope, id)
    {:ok, _booth} = Elections.delete_booth(scope, booth)

    conn
    |> put_flash(:info, "Booth deleted successfully.")
    |> redirect(to: ~p"/booths")
  end
end