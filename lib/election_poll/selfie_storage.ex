defmodule ElectionPoll.SelfieStorage do
  @moduledoc false

  alias ElectionPoll.Uploads

  def save_response_selfie(nil, nil, _response_id), do: {:ok, nil}
  def save_response_selfie("", "", _response_id), do: {:ok, nil}
  def save_response_selfie(_selfie, nil, _response_id), do: {:ok, nil}
  def save_response_selfie(_selfie, "", _response_id), do: {:ok, nil}

  def save_response_selfie(_selfie, selfie_base64, response_id) do
    try do
      Uploads.ensure_upload_dir!()

      binary = decode_base64_image(selfie_base64)
      filename = "#{response_id}.#{Uploads.upload_format()}"
      output_path = Uploads.file_path(filename)

      tmp_input = Path.join(System.tmp_dir!(), "#{response_id}_upload.bin")
      File.write!(tmp_input, binary)

      case Uploads.upload_format() do
        "webp" ->
          convert_to_webp!(tmp_input, output_path)

        _ ->
          File.cp!(tmp_input, output_path)
      end

      File.rm(tmp_input)

      {:ok, filename}
    rescue
      e ->
        {:error, Exception.message(e)}
    end
  end

  def delete_file(nil), do: :ok
  def delete_file(""), do: :ok

  def delete_file(filename) do
    path = Uploads.file_path(filename)

    if File.exists?(path) do
      File.rm(path)
    else
      :ok
    end
  end

  defp decode_base64_image("data:image/" <> _ = data_url) do
    case String.split(data_url, ",", parts: 2) do
      [_meta, base64_data] ->
        Base.decode64!(base64_data)

      _ ->
        raise "Invalid selfie data"
    end
  end

  defp decode_base64_image(base64_data) do
    Base.decode64!(base64_data)
  end

  defp convert_to_webp!(input_path, output_path) do
    {result, exit_code} =
      System.cmd("cwebp", ["-q", "90", input_path, "-o", output_path], stderr_to_stdout: true)

    if exit_code != 0 do
      raise "WebP conversion failed: #{result}"
    end
  end
end