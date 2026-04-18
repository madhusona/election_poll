defmodule ElectionPollWeb.PageController do
  use ElectionPollWeb, :controller

  alias ElectionPoll.Elections

  def home(conn, _params) do
    states = Elections.list_active_states_with_campaigns()
    render(conn, :home, states: states)
  end
end