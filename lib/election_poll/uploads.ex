defmodule ElectionPoll.Uploads do
  @moduledoc false

  def upload_dir do
    System.get_env("UPLOAD_DIR") || "/var/uploads/election_poll/selfies"
  end

  def upload_format do
    System.get_env("UPLOAD_FORMAT") || "webp"
  end

  def ensure_upload_dir! do
    File.mkdir_p!(upload_dir())
  end

  def file_path(filename) do
    Path.join(upload_dir(), filename)
  end

  def admin_url(path_or_filename) do
    filename = Path.basename(path_or_filename || "")
    "/admin/selfies/#{filename}"
  end
end