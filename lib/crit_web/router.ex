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

    get "/", PublicController, :index
  end

  scope "/user_management", CritWeb.UserManagement, as: :user_management do
    pipe_through :browser
    resources "/users", UserController, except: [:delete]
  end

  scope "/reflexive_user", CritWeb.ReflexiveUser, as: :reflexive_user do
    pipe_through :browser
    get "/password_using/:token_text", AuthorizationController, :fresh_password_form
    post "/fresh_password", AuthorizationController, :fresh_password

  end
  

  # Other scopes may use custom stacks.
  # scope "/api", CritWeb do
  #   pipe_through :api
  # end
end
