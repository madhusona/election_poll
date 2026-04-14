defmodule ElectionPollWeb.StateHTML do
  use ElectionPollWeb, :html

  embed_templates "state_html/*"

  @doc """
  Renders a state form.

  The form is defined in the template at
  state_html/state_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def state_form(assigns)
end
