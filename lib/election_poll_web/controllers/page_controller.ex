defmodule ElectionPollWeb.PageController do
  use ElectionPollWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
