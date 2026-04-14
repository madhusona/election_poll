defmodule ElectionPoll.PollingFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ElectionPoll.Polling` context.
  """

  @doc """
  Generate a response.
  """
  def response_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        latitude: 120.5,
        longitude: 120.5,
        mobile: "some mobile",
        secret_code: "some secret_code",
        selfie_path: "some selfie_path",
        submitted_at: ~U[2026-04-09 17:13:00Z],
        voter_name: "some voter_name"
      })

    {:ok, response} = ElectionPoll.Polling.create_response(scope, attrs)
    response
  end
end
