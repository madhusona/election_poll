defmodule ElectionPollWeb.SelfieController do
  use ElectionPollWeb, :controller

  alias ElectionPoll.Uploads

  def show(conn, %{"filename" => filename}) do
    safe_filename = Path.basename(filename)
    path = Uploads.file_path(safe_filename)

    if File.exists?(path) do
      send_file(conn, 200, path)
    else
      send_resp(conn, 404, "Not found")
    end
  end
end