defmodule LojaVirtual.Inventory do
  @moduledoc """
  Context for inventory management.

  Handles products and ingredients stock.
  """

  import Ecto.Query
  alias LojaVirtual.Repo
  alias LojaVirtual.Schemas.{Product, Ingredient}

  # =====================
  # Products
  # =====================

  @doc "Creates a new product"
  def create_product(attrs) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Gets a product by ID"
  def get_product(id), do: Repo.get(Product, id)

  @doc "Gets a product by SKU"
  def get_product_by_sku(sku) do
    Repo.get_by(Product, sku: sku)
  end

  @doc "Lists all active products"
  def list_products do
    Product
    |> where([p], p.active == true)
    |> order_by([p], asc: p.name)
    |> Repo.all()
  end

  @doc "Lists products with low stock"
  def list_low_stock_products do
    from(p in Product,
      where: p.active == true and p.stock_quantity <= p.min_stock_level,
      order_by: [asc: p.stock_quantity]
    )
    |> Repo.all()
  end

  @doc "Updates product stock"
  def update_product_stock(product_id, quantity_change) do
    from(p in Product,
      where: p.id == ^product_id,
      update: [inc: [stock_quantity: ^quantity_change]]
    )
    |> Repo.update_all([])
  end

  # =====================
  # Ingredients
  # =====================

  @doc "Creates a new ingredient"
  def create_ingredient(attrs) do
    %Ingredient{}
    |> Ingredient.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Gets an ingredient by ID"
  def get_ingredient(id), do: Repo.get(Ingredient, id)

  @doc "Lists all active ingredients"
  def list_ingredients do
    Ingredient
    |> where([i], i.active == true)
    |> order_by([i], asc: i.name)
    |> Repo.all()
  end

  @doc "Lists ingredients with low stock"
  def list_low_stock_ingredients do
    from(i in Ingredient,
      where: i.active == true,
      where: i.stock_quantity <= i.min_stock_level,
      order_by: [asc: i.stock_quantity]
    )
    |> Repo.all()
  end

  @doc "Updates ingredient stock"
  def update_ingredient_stock(ingredient_id, quantity_change) do
    quantity = Decimal.new(to_string(quantity_change))

    from(i in Ingredient,
      where: i.id == ^ingredient_id,
      update: [set: [stock_quantity: fragment("stock_quantity + ?", ^quantity)]]
    )
    |> Repo.update_all([])
  end

  @doc "Bulk update ingredient stock from an approved shipment"
  def replenish_ingredients(items) when is_list(items) do
    Repo.transaction(fn ->
      Enum.each(items, fn item ->
        ingredient_id = item["ingredient_id"] || item[:ingredient_id]
        quantity = item["quantity"] || item[:quantity]
        update_ingredient_stock(ingredient_id, quantity)
      end)
    end)
  end
end
