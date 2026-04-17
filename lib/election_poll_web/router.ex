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

  

  

  
  # Other scopes may use custom stacks.
  # scope "/api", ElectionPollWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:election_poll, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ElectionPollWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ElectionPollWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ElectionPollWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
      live "/campaigns/:id/dashboard", CampaignDashboardLive, :show
    end
    #get "/campaigns/:id/dashboard", CampaignDashboardController, :index
    post "/users/update-password", UserSessionController, :update_password
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

    resources "/states", StateController
    resources "/constituencies", ConstituencyController
    resources "/candidates", CandidateController
    resources "/campaigns", CampaignController
    resources "/booths", BoothController
    get "/responses/export", ResponseController, :export_csv
    resources "/responses", ResponseController, only: [:index, :show]
    
   
    get "/admin/uploads/selfies/:filename", SecureUploadController, :show_selfie
    get "/admin/selfies/:filename", SelfieController, :show
  end
end
