defmodule ElectionPollWeb.ConstituencyHTML do
  use ElectionPollWeb, :html

  embed_templates "constituency_html/*"

  @doc """
  Renders a constituency form.

  The form is defined in the template at
  constituency_html/constituency_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def constituency_form(assigns)
end
