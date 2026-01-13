defmodule LojaVirtual.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :price, :decimal, precision: 10, scale: 2, null: false
      add :stock_quantity, :integer, default: 0, null: false
      add :min_stock_level, :integer, default: 5, null: false
      add :sku, :string, null: false
      add :active, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:products, [:sku])
    create index(:products, [:active])
  end
end
