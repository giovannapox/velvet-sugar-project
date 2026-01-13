defmodule LojaVirtualWeb.HealthController do
  @moduledoc """
  Health check endpoint for monitoring.
  """
  use LojaVirtualWeb, :controller

  def check(conn, _params) do
    # Check database connection
    db_status = case Ecto.Adapters.SQL.query(LojaVirtual.Repo, "SELECT 1", []) do
      {:ok, _} -> "healthy"
      {:error, _} -> "unhealthy"
    end

    # Check Broadway pipelines
    pipelines_status = check_pipelines()

    # Check Kafka producer
    kafka_status = check_kafka_producer()

    status = if db_status == "healthy" and pipelines_status == "healthy" and kafka_status == "healthy" do
      :ok
    else
      :service_unavailable
    end

    conn
    |> put_status(status)
    |> json(%{
      status: if(status == :ok, do: "healthy", else: "unhealthy"),
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      checks: %{
        database: db_status,
        pipelines: pipelines_status,
        kafka_producer: kafka_status
      }
    })
  end

  defp check_pipelines do
    pipelines = [
      LojaVirtual.Pipelines.OrdersNewPipeline,
      LojaVirtual.Pipelines.OrdersPaidPipeline,
      LojaVirtual.Pipelines.ShippingReadyPipeline
    ]

    all_alive = Enum.all?(pipelines, fn pipeline ->
      Process.whereis(pipeline) != nil
    end)

    if all_alive, do: "healthy", else: "unhealthy"
  end

  defp check_kafka_producer do
    case :brod.get_partitions_count(:loja_virtual_producer, "orders.new") do
      {:ok, _count} -> "healthy"
      {:error, _} -> "unhealthy"
    end
  rescue
    _ -> "unhealthy"
  end
end
