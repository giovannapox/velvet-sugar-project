# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     LojaVirtual.Repo.insert!(%LojaVirtual.SomeSchema{})
#

alias LojaVirtual.Repo
alias LojaVirtual.Schemas.{Product, Ingredient}

IO.puts("🌱 Seeding database...")

# =====================
# Products (Ready-made)
# =====================

products = [
  %{
    name: "Bolo de Chocolate",
    description: "Delicioso bolo de chocolate com cobertura cremosa",
    price: Decimal.new("45.00"),
    stock_quantity: 10,
    min_stock_level: 3,
    sku: "BOLO-CHOC-001"
  },
  %{
    name: "Torta de Limão",
    description: "Torta de limão com merengue italiano",
    price: Decimal.new("38.00"),
    stock_quantity: 8,
    min_stock_level: 2,
    sku: "TORTA-LIM-001"
  },
  %{
    name: "Brigadeiro Gourmet (100g)",
    description: "Brigadeiro artesanal com chocolate belga",
    price: Decimal.new("15.00"),
    stock_quantity: 25,
    min_stock_level: 10,
    sku: "BRIG-GOUR-001"
  },
  %{
    name: "Pão de Mel",
    description: "Pão de mel recheado com doce de leite",
    price: Decimal.new("8.00"),
    stock_quantity: 30,
    min_stock_level: 10,
    sku: "PAO-MEL-001"
  },
  %{
    name: "Coxinha (unidade)",
    description: "Coxinha de frango com catupiry",
    price: Decimal.new("6.50"),
    stock_quantity: 50,
    min_stock_level: 15,
    sku: "COX-FRAN-001"
  },
  %{
    name: "Empada de Palmito",
    description: "Empada artesanal de palmito",
    price: Decimal.new("7.00"),
    stock_quantity: 40,
    min_stock_level: 12,
    sku: "EMP-PALM-001"
  }
]

Enum.each(products, fn product_attrs ->
  case Repo.get_by(Product, sku: product_attrs.sku) do
    nil ->
      %Product{}
      |> Product.changeset(product_attrs)
      |> Repo.insert!()
      IO.puts("  ✅ Product: #{product_attrs.name}")
    _existing ->
      IO.puts("  ⏭️  Product already exists: #{product_attrs.name}")
  end
end)

# =====================
# Ingredients (for custom orders)
# =====================

ingredients = [
  %{
    name: "Farinha de Trigo",
    description: "Farinha de trigo tipo 1",
    unit: :kg,
    stock_quantity: Decimal.new("25.0"),
    min_stock_level: Decimal.new("10.0"),
    cost_per_unit: Decimal.new("5.50"),
    supplier_code: "FARIN-001"
  },
  %{
    name: "Açúcar Refinado",
    description: "Açúcar refinado branco",
    unit: :kg,
    stock_quantity: Decimal.new("20.0"),
    min_stock_level: Decimal.new("8.0"),
    cost_per_unit: Decimal.new("4.00"),
    supplier_code: "ACUCAR-001"
  },
  %{
    name: "Ovos",
    description: "Ovos caipiras",
    unit: :un,
    stock_quantity: Decimal.new("100"),
    min_stock_level: Decimal.new("30"),
    cost_per_unit: Decimal.new("1.20"),
    supplier_code: "OVOS-001"
  },
  %{
    name: "Leite Integral",
    description: "Leite integral pasteurizado",
    unit: :l,
    stock_quantity: Decimal.new("15.0"),
    min_stock_level: Decimal.new("5.0"),
    cost_per_unit: Decimal.new("6.00"),
    supplier_code: "LEITE-001"
  },
  %{
    name: "Chocolate em Pó",
    description: "Chocolate em pó 50% cacau",
    unit: :kg,
    stock_quantity: Decimal.new("5.0"),
    min_stock_level: Decimal.new("2.0"),
    cost_per_unit: Decimal.new("25.00"),
    supplier_code: "CHOCO-001"
  },
  %{
    name: "Manteiga",
    description: "Manteiga sem sal",
    unit: :kg,
    stock_quantity: Decimal.new("8.0"),
    min_stock_level: Decimal.new("3.0"),
    cost_per_unit: Decimal.new("35.00"),
    supplier_code: "MANT-001"
  },
  %{
    name: "Fermento Químico",
    description: "Fermento em pó",
    unit: :g,
    stock_quantity: Decimal.new("500"),
    min_stock_level: Decimal.new("200"),
    cost_per_unit: Decimal.new("0.08"),
    supplier_code: "FERM-001"
  },
  %{
    name: "Extrato de Baunilha",
    description: "Extrato natural de baunilha",
    unit: :ml,
    stock_quantity: Decimal.new("200"),
    min_stock_level: Decimal.new("50"),
    cost_per_unit: Decimal.new("0.50"),
    supplier_code: "BAUN-001"
  },
  %{
    name: "Leite Condensado",
    description: "Leite condensado",
    unit: :g,
    stock_quantity: Decimal.new("2000"),
    min_stock_level: Decimal.new("500"),
    cost_per_unit: Decimal.new("0.02"),
    supplier_code: "LCOND-001"
  },
  %{
    name: "Creme de Leite",
    description: "Creme de leite fresco",
    unit: :ml,
    stock_quantity: Decimal.new("1500"),
    min_stock_level: Decimal.new("500"),
    cost_per_unit: Decimal.new("0.03"),
    supplier_code: "CREME-001"
  }
]

Enum.each(ingredients, fn ingredient_attrs ->
  case Repo.get_by(Ingredient, supplier_code: ingredient_attrs.supplier_code) do
    nil ->
      %Ingredient{}
      |> Ingredient.changeset(ingredient_attrs)
      |> Repo.insert!()
      IO.puts("  ✅ Ingredient: #{ingredient_attrs.name}")
    _existing ->
      IO.puts("  ⏭️  Ingredient already exists: #{ingredient_attrs.name}")
  end
end)

IO.puts("")
IO.puts("🎉 Database seeded successfully!")
IO.puts("")
IO.puts("📊 Summary:")
IO.puts("   Products: #{Repo.aggregate(Product, :count)}")
IO.puts("   Ingredients: #{Repo.aggregate(Ingredient, :count)}")
IO.puts("")
IO.puts("🚀 Ready to run:")
IO.puts("   1. docker-compose up -d  (start Kafka & PostgreSQL)")
IO.puts("   2. mix phx.server        (start Phoenix)")
IO.puts("   3. Visit http://localhost:4000/loja")
