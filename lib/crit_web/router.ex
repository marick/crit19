defmodule CritWeb.Router do
  use CritWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CritWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  scope "/accounts", CritWeb.Accounts, as: :accounts do
    pipe_through :browser

    resources "/users", UserController, except: [:delete]
  end

  scope "/auth", CritWeb do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/identity/callback", AuthController, :identity_callback
    get "/confirm_account/:token_text", AuthController, :set_password
    delete "/", AuthController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", CritWeb do
  #   pipe_through :api
  # end
end
