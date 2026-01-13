defmodule LojaVirtualWeb.Api.InventoryController do
  @moduledoc """
  API controller for inventory queries.
  """
  use LojaVirtualWeb, :controller

  alias LojaVirtual.Inventory

  @doc "Lists all active products"
  def list_products(conn, _params) do
    products = Inventory.list_products()

    conn
    |> json(%{
      success: true,
      products: Enum.map(products, fn p ->
        %{
          id: p.id,
          name: p.name,
          description: p.description,
          price: Decimal.to_float(p.price),
          stock_quantity: p.stock_quantity,
          sku: p.sku
        }
      end)
    })
  end

  @doc "Lists all active ingredients"
  def list_ingredients(conn, _params) do
    ingredients = Inventory.list_ingredients()

    conn
    |> json(%{
      success: true,
      ingredients: Enum.map(ingredients, fn i ->
        %{
          id: i.id,
          name: i.name,
          unit: i.unit,
          stock_quantity: Decimal.to_float(i.stock_quantity),
          cost_per_unit: Decimal.to_float(i.cost_per_unit)
        }
      end)
    })
  end

  @doc "Lists items with low stock"
  def low_stock(conn, _params) do
    low_products = Inventory.list_low_stock_products()
    low_ingredients = Inventory.list_low_stock_ingredients()

    conn
    |> json(%{
      success: true,
      low_stock: %{
        products: Enum.map(low_products, fn p ->
          %{
            id: p.id,
            name: p.name,
            current: p.stock_quantity,
            minimum: p.min_stock_level
          }
        end),
        ingredients: Enum.map(low_ingredients, fn i ->
          %{
            id: i.id,
            name: i.name,
            current: Decimal.to_float(i.stock_quantity),
            minimum: Decimal.to_float(i.min_stock_level),
            unit: i.unit
          }
        end)
      }
    })
  end
end
