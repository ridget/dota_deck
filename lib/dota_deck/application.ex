defmodule DotaDeck.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DotaDeckWeb.Telemetry,
      DotaDeck.Repo,
      {DNSCluster, query: Application.get_env(:dota_deck, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DotaDeck.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: DotaDeck.Finch},
      # Start a worker by calling: DotaDeck.Worker.start_link(arg)
      # {DotaDeck.Worker, arg},
      # Start to serve requests, typically the last entry
      DotaDeckWeb.Endpoint,
      {Nx.Serving,
       serving: DotaDeck.Models.Embedding.serving(defn_options: [compiler: EXLA]),
       batch_size: 3,
       batch_timeout: 100,
       name: Embedding},
      {Nx.Serving,
       serving: DotaDeck.Models.SpeechTranscription.serving(defn_options: [compiler: EXLA]),
       batch_size: 3,
       batch_timeout: 100,
       name: SpeechTranscription}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DotaDeck.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DotaDeckWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
