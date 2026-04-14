defmodule ElectionPoll.ElectionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ElectionPoll.Elections` context.
  """

  @doc """
  Generate a state.
  """
  def state_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        code: "some code",
        display_order: 42,
        is_active: true,
        name: "some name"
      })

    {:ok, state} = ElectionPoll.Elections.create_state(scope, attrs)
    state
  end

  @doc """
  Generate a constituency.
  """
  def constituency_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        code: "some code",
        display_order: 42,
        is_active: true,
        name: "some name"
      })

    {:ok, constituency} = ElectionPoll.Elections.create_constituency(scope, attrs)
    constituency
  end

  @doc """
  Generate a candidate.
  """
  def candidate_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        abbreviation: "some abbreviation",
        alliance: "some alliance",
        candidate_name: "some candidate_name",
        color: "some color",
        display_order: 42,
        is_active: true,
        party_full_name: "some party_full_name",
        symbol_image: "some symbol_image",
        symbol_name: "some symbol_name"
      })

    {:ok, candidate} = ElectionPoll.Elections.create_candidate(scope, attrs)
    candidate
  end

  @doc """
  Generate a campaign.
  """
  def campaign_fixture(scope, attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        ends_at: ~U[2026-04-09 17:14:00Z],
        is_active: true,
        name: "some name",
        secret_code: "some secret_code",
        slug: "some slug",
        starts_at: ~U[2026-04-09 17:14:00Z]
      })

    {:ok, campaign} = ElectionPoll.Elections.create_campaign(scope, attrs)
    campaign
  end
end
