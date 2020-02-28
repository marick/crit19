defmodule CritWeb.Router do
  use CritWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug CritWeb.Plugs.FetchUser
    plug CritWeb.Plugs.AddAuditLog
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

IO.puts(
    """
    ===============================================================
    When adding new routes, don't forget to add authorization tests
    ===============================================================
    """)

  scope "/", CritWeb do
    pipe_through :browser

    get "/", PublicController, :index
    get "/login", PublicController, :redirect_to_login
  end

  scope "/user_management", CritWeb.UserManagement, as: :user_management do
    pipe_through :browser
    resources "/users", UserController, except: [:delete]
  end

  scope "/user", CritWeb.CurrentUser, as: :current_user do
    pipe_through :browser
    get "/create_password/:token_text", SettingsController, :fresh_password_form
    post "/fresh_password", SettingsController, :set_fresh_password

    get "/home", SessionController, :home
    get "/login", SessionController, :get_login_form
    post "/login", SessionController, :try_login 
    delete "/logout", SessionController, :logout
  end


  scope "/setup", CritWeb.Setup, as: :setup do
    pipe_through :browser

    scope "/animals" do 
      get "/bulk_create", AnimalController, :bulk_create_form
      post "/bulk_create", AnimalController, :bulk_create
      get "/update_form/:animal_id", AnimalController, :update_form
      put "/update/:animal_id", AnimalController, :update
      post "/update/:animal_id", AnimalController, :update
      get "/", AnimalController, :index
      get "/:animal_id", AnimalController, :_show
    end
  end

  scope "/reservation", CritWeb.Reservations do
    pipe_through :browser

    scope "/after_the_fact" do 
      get "/", AfterTheFactController, :start
      post "/species_and_time", AfterTheFactController, :put_species_and_time
      post "/animals", AfterTheFactController, :put_animals
      post "/procedures", AfterTheFactController, :put_procedures
    end

    get "/by_dates_form", ReservationController, :by_dates_form
    post "/by_dates", ReservationController, :by_dates
    get "/calendar/weekly", ReservationController, :weekly_calendar
    get "/:reservation_id", ReservationController, :show
  end
  
  # Other scopes may use custom stacks.
  # scope "/api", CritWeb do
  #   pipe_through :api
  # end
end
