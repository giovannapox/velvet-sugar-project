defmodule LojaVirtual.Schemas.Order do
  @moduledoc """
  Schema for customer orders.

  Order lifecycle:
  new -> paid -> processing -> shipped -> delivered

  Order types:
  - pronto: Ready-made products (goes through stock.product.check)
  - personalizado: Custom orders (goes through stock.ingredient.check -> kitchen)
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [:new, :paid, :processing, :shipped, :delivered, :cancelled]
  @types [:pronto, :personalizado]

  schema "orders" do
    field :status, Ecto.Enum, values: @statuses, default: :new
    field :type, Ecto.Enum, values: @types
    field :total, :decimal
    field :customer_email, :string
    field :customer_name, :string
    field :delivery_address, :string

    # Metadata for tracking
    field :paid_at, :utc_datetime
    field :shipped_at, :utc_datetime
    field :delivered_at, :utc_datetime

    has_many :items, LojaVirtual.Schemas.OrderItem

    timestamps()
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:status, :type, :total, :customer_email, :customer_name,
                    :delivery_address, :paid_at, :shipped_at, :delivered_at])
    |> validate_required([:type, :total, :customer_email, :customer_name, :delivery_address])
    |> validate_format(:customer_email, ~r/@/)
    |> validate_number(:total, greater_than: 0)
  end

  def statuses, do: @statuses
  def types, do: @types
end
