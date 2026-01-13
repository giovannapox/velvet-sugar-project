defmodule LojaVirtual.Kafka.Producer do
  @moduledoc """
  Kafka producer using brod (real Kafka client).
  """

  require Logger

  alias LojaVirtual.Kafka.Config

  @doc """
  Starts the brod Kafka client.
  """
  def start_link(_opts \\ []) do
    hosts = Config.hosts_tuple()
    client_id = Config.client_id()

    case :brod.start_client(hosts, client_id, client_config()) do
      :ok ->
        Logger.info("[Kafka Producer] Started successfully on #{inspect(hosts)}")
        {:ok, self()}

      {:error, {:already_started, _pid}} ->
        Logger.debug("[Kafka Producer] Already started")
        {:ok, self()}

      {:error, reason} ->
        Logger.error("[Kafka Producer] Failed to start: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Publishes a message to a Kafka topic.
  """
  def publish(topic, key, message) when is_binary(topic) and is_binary(key) do
    payload = Jason.encode!(message)
    client_id = Config.client_id()

    # Partition selection strategy: hash the key
    partition = :hash

    case :brod.produce_sync(client_id, topic, partition, key, payload) do
      :ok ->
        Logger.debug("[Kafka] Published to #{topic}: key=#{key}")
        :ok

      {:ok, _offset} ->
        Logger.debug("[Kafka] Published to #{topic}: key=#{key}")
        :ok

      {:error, reason} ->
        Logger.error("[Kafka] Failed to publish to #{topic}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Publishes a message with auto-generated key.
  """
  def publish(topic, message) when is_map(message) do
    key = message[:id] || message["id"] || generate_key()
    publish(topic, to_string(key), message)
  end

  defp client_config do
    [
      # Request at least 1 ack from broker (leader)
      required_acks: 1,
      # Allow producer to receive messages up to 10MB
      max_request_size: 10_000_000,
      # No compression (snappy requires C compiler)
      compression: :none
    ]
  end

  defp generate_key do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
