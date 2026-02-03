defmodule OhmywordWeb.Router do
  use OhmywordWeb, :router

  import OhmywordWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OhmywordWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admins_only do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OhmywordWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug :require_authenticated_user
    plug OhmywordWeb.Plugs.RequireAdmin
  end

  scope "/", OhmywordWeb do
    pipe_through :browser

    get "/", PageController, :home

    live_session :public, on_mount: [{OhmywordWeb.UserAuth, :mount_current_scope}] do
      live "/flashcards", FlashcardLive, :index
    end
  end

  use Kaffy.Routes,
    scope: "/admin/kaffy",
    pipe_through: [:admins_only]

  # Other scopes may use custom stacks.
  # scope "/api", OhmywordWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ohmyword, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OhmywordWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", OhmywordWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{OhmywordWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", OhmywordWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{OhmywordWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/confirm/:token", UserLive.Confirmation, :new
      live "/users/resend-confirmation", UserLive.ResendConfirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  scope "/admin", OhmywordWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin_user]

    live_session :admin,
      on_mount: [{OhmywordWeb.UserAuth, :require_admin_user}] do
      live "/dashboard", AdminDashboardLive, :index
    end
  end
end
