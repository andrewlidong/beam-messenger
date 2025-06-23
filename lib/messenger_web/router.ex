defmodule MessengerWeb.Router do
  use MessengerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MessengerWeb.Layouts, :root}
    # Make current_user available in assigns for all browser requests
    plug MessengerWeb.UserAuth, :fetch_current_user
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Pipelines for authentication control -----------------------------

  # Redirects to "/" if user IS already authenticated
  pipeline :redirect_if_authenticated_user do
    plug MessengerWeb.UserAuth, :redirect_if_user_is_authenticated
  end

  # Ensures the user IS authenticated, otherwise sends to login
  pipeline :require_authenticated_user do
    plug MessengerWeb.UserAuth, :require_authenticated_user
  end

  scope "/", MessengerWeb do
    pipe_through :browser

    # Chat routes
    get "/", ChatController, :index
    resources "/chat", ChatController
    get "/chat/:room_id/history", ChatController, :history
    post "/chat/:room_id/join", ChatController, :join
    post "/chat/:room_id/leave", ChatController, :leave
  end

  # ---------------- Guest-only routes (login / register) -------------
  scope "/", MessengerWeb do
    pipe_through [:browser, :redirect_if_authenticated_user]

    get  "/login",  SessionController,      :new
    post "/login",  SessionController,      :create

    get  "/register", RegistrationController, :new
    post "/register", RegistrationController, :create
  end

  # -------------- Authenticated-only routes (profile / logout) -------
  scope "/", MessengerWeb do
    pipe_through [:browser, :require_authenticated_user]

    get    "/profile",               RegistrationController, :edit
    put    "/profile",               RegistrationController, :update
    get    "/profile/password",      RegistrationController, :edit_password
    put    "/profile/password",      RegistrationController, :update_password
    delete "/profile/:id",           RegistrationController, :delete

    delete "/logout",  SessionController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", MessengerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:messenger, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MessengerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
