defmodule LojaVirtual.Repo.Migrations.CreateOrderItems do
  use Ecto.Migration

  def change do
    create table(:order_items, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :quantity, :integer, null: false
      add :unit_price, :decimal, precision: 10, scale: 2, null: false
      add :subtotal, :decimal, precision: 10, scale: 2, null: false

      add :order_id, references(:orders, type: :binary_id, on_delete: :delete_all), null: false
      add :product_id, references(:products, type: :binary_id, on_delete: :nilify_all)
      add :ingredient_id, references(:ingredients, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create index(:order_items, [:order_id])
    create index(:order_items, [:product_id])
    create index(:order_items, [:ingredient_id])
  end
end
