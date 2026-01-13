defmodule LojaVirtualWeb.Api.OrderController do
  @moduledoc """
  API controller for order management.

  Endpoints:
  - POST /api/orders - Create a new order (publishes to orders.new)
  - GET /api/orders/:id - Get order details
  - GET /api/orders - List orders
  """
  use LojaVirtualWeb, :controller

  alias LojaVirtual.Orders

  action_fallback LojaVirtualWeb.FallbackController

  @doc """
  Creates a new order and publishes to Kafka.

  ## Request Body
  ```json
  {
    "type": "pronto" | "personalizado",
    "customer_name": "string",
    "customer_email": "string",
    "delivery_address": "string",
    "items": [
      {"product_id": "uuid", "quantity": 1, "unit_price": 10.0}
      // or for custom orders:
      {"ingredient_id": "uuid", "quantity": 1, "unit_price": 5.0}
    ]
  }
  ```
  """
  def create(conn, params) do
    order_params = %{
      type: String.to_existing_atom(params["type"]),
      customer_name: params["customer_name"],
      customer_email: params["customer_email"],
      delivery_address: params["delivery_address"],
      total: calculate_total(params["items"]),
      items: params["items"]
    }

    case Orders.create_order(order_params) do
      {:ok, order} ->
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          order: %{
            id: order.id,
            status: order.status,
            type: order.type,
            total: Decimal.to_float(order.total),
            message: "Order created and sent to payment processing"
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          errors: format_errors(changeset)
        })
    end
  end

  @doc "Gets a single order by ID"
  def show(conn, %{"id" => id}) do
    case Orders.get_order_with_items(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: "Order not found"})

      order ->
        conn
        |> json(%{
          success: true,
          order: %{
            id: order.id,
            status: order.status,
            type: order.type,
            total: Decimal.to_float(order.total),
            customer_name: order.customer_name,
            customer_email: order.customer_email,
            delivery_address: order.delivery_address,
            paid_at: order.paid_at,
            shipped_at: order.shipped_at,
            delivered_at: order.delivered_at,
            created_at: order.inserted_at
          }
        })
    end
  end

  @doc "Lists orders with optional filters"
  def index(conn, params) do
    limit = String.to_integer(params["limit"] || "50")
    orders = Orders.list_orders(limit: limit)

    conn
    |> json(%{
      success: true,
      orders: Enum.map(orders, fn order ->
        %{
          id: order.id,
          status: order.status,
          type: order.type,
          total: Decimal.to_float(order.total),
          customer_email: order.customer_email,
          created_at: order.inserted_at
        }
      end)
    })
  end

  # Private helpers

  defp calculate_total(nil), do: Decimal.new(0)
  defp calculate_total(items) do
    Enum.reduce(items, Decimal.new(0), fn item, acc ->
      price = Decimal.new(to_string(item["unit_price"] || 0))
      qty = item["quantity"] || 1
      Decimal.add(acc, Decimal.mult(price, qty))
    end)
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
