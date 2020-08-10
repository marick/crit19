defmodule Crit.MixProject do
  use Mix.Project

  def project do
    [
      app: :crit,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Crit.Application, []},
      extra_applications: [:logger, :runtime_tools, :calendar]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.7"},
      {:phoenix_pubsub, "~> 1.1"},
      {:phoenix_ecto, "~> 4.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:calendar, "~> 1.0"},
      {:faker, "~> 0.12", only: :test},
      {:ex_machina, "~> 2.3"},
      {:pbkdf2_elixir, "~> 1.0"},
      {:puid, "~> 1.0"},
      {:assertions, "~> 0.10", only: :test},
      {:tzdata, "~> 1.0.1"},
      {:elixir_uuid, "~> 1.0"},
      {:con_cache, "~> 0.14"},
      {:mockery, "~> 2.3.0", runtime: false},
      {:inflex, "~> 2.0"},
      {:recase, "~> 0.6.0"},
      {:conjunction, "~> 1.0.2"},       
      {:phoenix_integration, "~> 0.8", only: :test},
      {:flow_assertions, "~> 0.1", only: :test},
      {:deep_merge, "~> 1.0"},
      {:ex_contract, "~> 0.1.1"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      server: ["phx.server"],
    ]
  end
end
