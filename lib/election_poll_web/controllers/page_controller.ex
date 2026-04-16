defmodule ElectionPollWeb.PageController do
  use ElectionPollWeb, :controller
  alias ElectionPoll.Elections
  def home(conn, _params) do
    campaigns = Elections.list_active_campaigns()
    render(conn, :home, campaigns: campaigns)
  end
end
