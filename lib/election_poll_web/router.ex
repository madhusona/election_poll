defmodule ElectionPollWeb.Router do
  use ElectionPollWeb, :router

  import ElectionPollWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html", "json"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ElectionPollWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug :fetch_current_scope_for_user
    plug :require_authenticated_user
    plug ElectionPollWeb.Plugs.RequireAdmin
  end

  scope "/", ElectionPollWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/", ElectionPollWeb do
    pipe_through :browser

    get "/c/:slug", PublicPollingController, :show
    post "/c/:slug/submit", PublicPollingController, :submit
    get "/c/:slug/success", PublicPollingController, :success

    get "/poll/:slug/permission-denied", PollFlowController, :permission_denied
    get "/poll/:slug", PollFlowController, :constituency
    get "/poll/:slug/booth", PollFlowController, :booth
    get "/poll/:slug/demographic", PollFlowController, :demographic
    get "/poll/:slug/vote", PollFlowController, :vote
    post "/poll/:slug/submit", PollFlowController, :submit
    get "/poll/:slug/success", PollFlowController, :success
    get "/poll/:slug/access", PollFlowController, :access
    post "/poll/:slug/submit_ajax", PollFlowController, :submit_ajax
  end

  if Application.compile_env(:election_poll, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ElectionPollWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  scope "/", ElectionPollWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ElectionPollWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/analytics", CampaignDashboardLive, :show
    end

    post "/users/update-password", UserSessionController, :update_password

    get "/responses/export", ResponseController, :export_csv
    resources "/responses", ResponseController, only: [:index, :show]

    get "/admin/uploads/selfies/:filename", SecureUploadController, :show_selfie
    get "/admin/selfies/:filename", SelfieController, :show
  end

  scope "/", ElectionPollWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{ElectionPollWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  scope "/", ElectionPollWeb do
    pipe_through [:browser, :admin]

    get "/admin", AdminController, :index
    get "/admin/user-restrictions", AdminRestrictionController, :index
    post "/admin/user-restrictions/:user_id", AdminRestrictionController, :save

    resources "/states", StateController
    resources "/constituencies", ConstituencyController
    resources "/candidates", CandidateController
    resources "/campaigns", CampaignController
    resources "/booths", BoothController
  end
end