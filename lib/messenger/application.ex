defmodule Messenger.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MessengerWeb.Telemetry,
      Messenger.Repo,
      {DNSCluster, query: Application.get_env(:messenger, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Messenger.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Messenger.Finch},
      # Start a worker by calling: Messenger.Worker.start_link(arg)
      # {Messenger.Worker, arg},
      # Start to serve requests, typically the last entry
      MessengerWeb.Presence,
      MessengerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Messenger.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MessengerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
