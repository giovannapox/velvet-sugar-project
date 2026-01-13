defmodule LojaVirtual.Schemas.Product do
  @moduledoc """
  Schema for ready-made products.

  These are products that are already prepared and just need to be shipped.
  Used when order.type == :pronto
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "products" do
    field :name, :string
    field :description, :string
    field :price, :decimal
    field :stock_quantity, :integer, default: 0
    field :min_stock_level, :integer, default: 5
    field :sku, :string
    field :active, :boolean, default: true

    timestamps()
  end

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :description, :price, :stock_quantity, :min_stock_level, :sku, :active])
    |> validate_required([:name, :price, :sku])
    |> validate_number(:price, greater_than: 0)
    |> validate_number(:stock_quantity, greater_than_or_equal_to: 0)
    |> unique_constraint(:sku)
  end
end
