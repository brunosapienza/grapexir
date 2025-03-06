defmodule Grapexir.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Grapexir.Repo,
      {DNSCluster, query: Application.get_env(:grapexir, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Grapexir.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Grapexir.Finch}
      # Start a worker by calling: Grapexir.Worker.start_link(arg)
      # {Grapexir.Worker, arg}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Grapexir.Supervisor)
  end
end
