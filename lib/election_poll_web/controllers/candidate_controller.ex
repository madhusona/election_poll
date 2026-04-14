defmodule ElectionPollWeb.CandidateController do
  use ElectionPollWeb, :controller

  alias ElectionPoll.Elections
  alias ElectionPoll.Elections.Candidate

  def index(conn, _params) do
    candidates = Elections.list_candidates(conn.assigns.current_scope)
    render(conn, :index, candidates: candidates)
  end

  def new(conn, _params) do
    changeset =
      Elections.change_candidate(conn.assigns.current_scope, %Candidate{
        user_id: conn.assigns.current_scope.user.id
      })

    constituencies = Elections.list_constituencies(conn.assigns.current_scope)

    render(conn, :new,
      changeset: changeset,
      constituencies: constituencies
    )
  end

  def create(conn, %{"candidate" => candidate_params}) do
    case Elections.create_candidate(conn.assigns.current_scope, candidate_params) do
      {:ok, candidate} ->
        conn
        |> put_flash(:info, "Candidate created successfully.")
        |> redirect(to: ~p"/candidates/#{candidate}")

      {:error, %Ecto.Changeset{} = changeset} ->
        constituencies = Elections.list_constituencies(conn.assigns.current_scope)

        render(conn, :new,
          changeset: changeset,
          constituencies: constituencies
        )
    end
  end

  def show(conn, %{"id" => id}) do
    candidate = Elections.get_candidate!(conn.assigns.current_scope, id)
    render(conn, :show, candidate: candidate)
  end

  def edit(conn, %{"id" => id}) do
    candidate = Elections.get_candidate!(conn.assigns.current_scope, id)
    changeset = Elections.change_candidate(conn.assigns.current_scope, candidate)
    constituencies = Elections.list_constituencies(conn.assigns.current_scope)

    render(conn, :edit,
      candidate: candidate,
      changeset: changeset,
      constituencies: constituencies
    )
  end

  def update(conn, %{"id" => id, "candidate" => candidate_params}) do
    candidate = Elections.get_candidate!(conn.assigns.current_scope, id)

    case Elections.update_candidate(conn.assigns.current_scope, candidate, candidate_params) do
      {:ok, candidate} ->
        conn
        |> put_flash(:info, "Candidate updated successfully.")
        |> redirect(to: ~p"/candidates/#{candidate}")

      {:error, %Ecto.Changeset{} = changeset} ->
        constituencies = Elections.list_constituencies(conn.assigns.current_scope)

        render(conn, :edit,
          candidate: candidate,
          changeset: changeset,
          constituencies: constituencies
        )
    end
  end

  def delete(conn, %{"id" => id}) do
    candidate = Elections.get_candidate!(conn.assigns.current_scope, id)
    {:ok, _candidate} = Elections.delete_candidate(conn.assigns.current_scope, candidate)

    conn
    |> put_flash(:info, "Candidate deleted successfully.")
    |> redirect(to: ~p"/candidates")
  end
end