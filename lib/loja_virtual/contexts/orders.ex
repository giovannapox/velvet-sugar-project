defmodule LojaVirtual.Orders do
  @moduledoc """
  Context for order management.

  Handles creation, updates, and querying of orders.
  """

  import Ecto.Query
  alias LojaVirtual.Repo
  alias LojaVirtual.Schemas.{Order, OrderItem}
  alias LojaVirtual.Kafka.{Topics, Producer}

  @doc """
  Creates a new order and publishes to Kafka.
  """
  def create_order(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, order} ->
        # Publish to Kafka
        publish_order_created(order, attrs)
        {:ok, order}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Creates an order with items.
  """
  def create_order_with_items(order_attrs, items_attrs) do
    Repo.transaction(fn ->
      with {:ok, order} <- create_order_only(order_attrs),
           {:ok, items} <- create_order_items(order, items_attrs) do
        order = %{order | items: items}
        publish_order_created(order, order_attrs)
        order
      else
        {:error, changeset} -> Repo.rollback(changeset)
      end
    end)
  end

  defp create_order_only(attrs) do
    %Order{}
    |> Order.changeset(attrs)
    |> Repo.insert()
  end

  defp create_order_items(order, items_attrs) do
    items =
      Enum.map(items_attrs, fn item_attrs ->
        %OrderItem{}
        |> OrderItem.changeset(Map.put(item_attrs, :order_id, order.id))
        |> Repo.insert!()
      end)

    {:ok, items}
  end

  defp publish_order_created(order, attrs) do
    event = %{
      id: order.id,
      type: to_string(order.type),
      total: Decimal.to_float(order.total),
      customer_email: order.customer_email,
      customer_name: order.customer_name,
      delivery_address: order.delivery_address,
      items: Map.get(attrs, :items, Map.get(attrs, "items", [])),
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Producer.publish(Topics.orders_new(), order.id, event)
  end

  @doc """
  Gets an order by ID.
  """
  def get_order(id) do
    Repo.get(Order, id)
  end

  @doc """
  Gets an order with items preloaded.
  """
  def get_order_with_items(id) do
    Order
    |> Repo.get(id)
    |> Repo.preload([:items])
  end

  @doc """
  Lists orders by status.
  """
  def list_orders_by_status(status) do
    Order
    |> where([o], o.status == ^status)
    |> order_by([o], desc: o.inserted_at)
    |> Repo.all()
  end

  @doc """
  Lists all orders.
  """
  def list_orders(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    Order
    |> order_by([o], desc: o.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Updates order status.
  """
  def update_order_status(order_id, status) do
    case get_order(order_id) do
      nil -> {:error, :not_found}
      order ->
        order
        |> Ecto.Changeset.change(%{status: status})
        |> Repo.update()
    end
  end
end
