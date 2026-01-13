defmodule LojaVirtual.Schemas.Ingredient do
  @moduledoc """
  Schema for raw ingredients.

  Used for custom orders (order.type == :personalizado).
  When stock is low, triggers supply.needed event.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @units [:kg, :g, :l, :ml, :un]

  schema "ingredients" do
    field :name, :string
    field :description, :string
    field :unit, Ecto.Enum, values: @units
    field :stock_quantity, :decimal, default: Decimal.new(0)
    field :min_stock_level, :decimal, default: Decimal.new(10)
    field :cost_per_unit, :decimal
    field :supplier_code, :string
    field :active, :boolean, default: true

    timestamps()
  end

  def changeset(ingredient, attrs) do
    ingredient
    |> cast(attrs, [:name, :description, :unit, :stock_quantity, :min_stock_level,
                    :cost_per_unit, :supplier_code, :active])
    |> validate_required([:name, :unit, :cost_per_unit])
    |> validate_number(:cost_per_unit, greater_than: 0)
    |> validate_number(:stock_quantity, greater_than_or_equal_to: 0)
  end

  def units, do: @units

  @doc "Checks if the ingredient needs restocking"
  def needs_restock?(%__MODULE__{stock_quantity: stock, min_stock_level: min}) do
    Decimal.compare(stock, min) == :lt
  end
end
