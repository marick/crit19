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
    plug :fetch_session
    plug CritWeb.Plugs.FetchUser
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
      put "/update/:animal_old_id", AnimalController, :update
      post "/update/:animal_old_id", AnimalController, :update
      get "/", AnimalController, :index
      get "/:animal_id", AnimalController, :_show
    end

    scope "/procedures" do 
      get "/bulk_creation_form", ProcedureController, :bulk_creation_form
      post "/bulk_create", ProcedureController, :bulk_create
    end
  end

  scope "/reservation/api", CritWeb.Reservations do
    pipe_through :api

    get "/week_data/:week_offset", ReservationController, :week_data
  end

  scope "/reservation", CritWeb.Reservations do
    pipe_through :browser

    scope "/after_the_fact" do 
      get "/", AfterTheFactController, :start
      post "/context", AfterTheFactController, :put_context
      post "/animals", AfterTheFactController, :put_animals
      post "/procedures", AfterTheFactController, :put_procedures
    end

    get "/by_dates_form", ReservationController, :by_dates_form
    post "/by_dates", ReservationController, :by_dates
    get "/calendar/weekly", ReservationController, :weekly_calendar
    get "/:reservation_id", ReservationController, :show
  end

  scope "/report", CritWeb.Reports, as: :reports do
    pipe_through :browser

    scope "/animals" do
      get "/use_form", AnimalReportController, :use_form
      post "/use/last_month", AnimalReportController, :use_last_month
    end
  end
end
