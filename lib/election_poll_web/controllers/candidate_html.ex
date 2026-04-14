defmodule ElectionPollWeb.CandidateHTML do
  use ElectionPollWeb, :html

  embed_templates "candidate_html/*"

  @doc """
  Renders a candidate form.

  The form is defined in the template at
  candidate_html/candidate_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil
  attr :constituencies, :list, default: []

  def candidate_form(assigns)
end