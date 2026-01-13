defmodule LojaVirtual.Kafka.Config do
  @moduledoc """
  Configuração centralizada do Kafka.
  Lê o host da variável de ambiente ou usa localhost como fallback.
  """

  @doc """
  Retorna a lista de hosts Kafka no formato esperado pelo BroadwayKafka.

  Docker interno: kafka:29092
  Local/externo:  localhost:9092
  """
  def hosts do
    host = System.get_env("KAFKA_HOST", "localhost")
    port = get_port(host)

    [{String.to_atom(host), port}]
  end

  @doc """
  Retorna hosts no formato de tupla para o brod client.
  """
  def hosts_tuple do
    host = System.get_env("KAFKA_HOST", "localhost")
    port = get_port(host)
    [{host, port}]
  end

  # Porta interna do Docker é 29092, externa é 9092
  defp get_port("kafka"), do: 29092
  defp get_port(_), do: 9092

  @doc """
  ID do cliente Kafka producer.
  """
  def client_id, do: :loja_virtual_producer
end
