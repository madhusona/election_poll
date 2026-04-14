defmodule ElectionPollWeb.SecureUploadController do
  use ElectionPollWeb, :controller

  def show_selfie(conn, %{"filename" => filename}) do
    user = conn.assigns.current_scope.user

    cond do
      is_nil(user) ->
        send_resp(conn, 403, "Forbidden")

      user.role != "admin" ->
        send_resp(conn, 403, "Forbidden")

      invalid_filename?(filename) ->
        send_resp(conn, 400, "Invalid filename")

      true ->
        path =
          Path.join([
            :code.priv_dir(:election_poll),
            "static",
            "uploads",
            "selfies",
            filename
          ])

        if File.exists?(path) do
          content_type = MIME.from_path(path) || "application/octet-stream"

          conn
          |> put_resp_content_type(content_type)
          |> put_resp_header("cache-control", "private, no-store, no-cache, must-revalidate")
          |> put_resp_header("pragma", "no-cache")
          |> put_resp_header("expires", "0")
          |> send_file(200, path)
        else
          send_resp(conn, 404, "File not found")
        end
    end
  end

  defp invalid_filename?(filename) do
    filename != Path.basename(filename) or
      String.contains?(filename, ["..", "/", "\\"])
  end
end