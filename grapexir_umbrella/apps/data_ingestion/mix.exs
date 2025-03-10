defmodule DataIngestion.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_ingestion,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DataIngestion.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      # {:sibling_app_in_umbrella, in_umbrella: true}
      {:grapexir, in_umbrella: true},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.2"},
      {:job_queue, "~> 0.1.0"}, # Background job processing,
      # {:quantum, "~> 3.5"} # Cron job scheduling
    ]
  end
end
