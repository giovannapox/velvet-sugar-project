defmodule LojaVirtual.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LojaVirtualWeb.Telemetry,
      LojaVirtual.Repo,
      {DNSCluster, query: Application.get_env(:loja_virtual, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LojaVirtual.PubSub},
      LojaVirtualWeb.Endpoint
    ] ++ kafka_children()

    opts = [strategy: :one_for_one, name: LojaVirtual.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp kafka_children do
    [
      # Kafka Producer (brod client)
      {Task, fn -> start_kafka_producer() end},

      # Broadway Pipelines (Kafka Consumers)
      LojaVirtual.Pipelines.OrdersNewPipeline,
      LojaVirtual.Pipelines.OrdersPaidPipeline,
      LojaVirtual.Pipelines.ShippingReadyPipeline
    ]
  end

  defp start_kafka_producer do
    # Wait for Kafka to be ready
    Process.sleep(2000)
    LojaVirtual.Kafka.Producer.start_link()
  end

  @impl true
  def config_change(changed, _new, removed) do
    LojaVirtualWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
