defmodule ElectionPollWeb.CampaignHTML do
  use ElectionPollWeb, :html

  embed_templates "campaign_html/*"

  @doc """
  Renders a campaign form.

  The form is defined in the template at
  campaign_html/campaign_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def campaign_form(assigns)
end
