defmodule LojaVirtual.Schemas.OrderItem do
  @moduledoc """
  Schema for order items.

  Can reference either a Product (ready-made) or an Ingredient (custom).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "order_items" do
    field :quantity, :integer
    field :unit_price, :decimal
    field :subtotal, :decimal

    belongs_to :order, LojaVirtual.Schemas.Order
    belongs_to :product, LojaVirtual.Schemas.Product
    belongs_to :ingredient, LojaVirtual.Schemas.Ingredient

    timestamps()
  end

  def changeset(order_item, attrs) do
    order_item
    |> cast(attrs, [:quantity, :unit_price, :subtotal, :order_id, :product_id, :ingredient_id])
    |> validate_required([:quantity, :unit_price, :order_id])
    |> validate_number(:quantity, greater_than: 0)
    |> calculate_subtotal()
  end

  defp calculate_subtotal(changeset) do
    case {get_change(changeset, :quantity), get_change(changeset, :unit_price)} do
      {qty, price} when not is_nil(qty) and not is_nil(price) ->
        put_change(changeset, :subtotal, Decimal.mult(price, qty))
      _ ->
        changeset
    end
  end
end
