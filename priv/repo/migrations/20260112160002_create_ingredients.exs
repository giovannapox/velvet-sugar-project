defmodule LojaVirtual.Repo.Migrations.CreateIngredients do
  use Ecto.Migration

  def change do
    create table(:ingredients, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :unit, :string, null: false
      add :stock_quantity, :decimal, precision: 10, scale: 3, default: 0, null: false
      add :min_stock_level, :decimal, precision: 10, scale: 3, default: 10, null: false
      add :cost_per_unit, :decimal, precision: 10, scale: 2, null: false
      add :supplier_code, :string
      add :active, :boolean, default: true, null: false

      timestamps()
    end

    create index(:ingredients, [:active])
    create index(:ingredients, [:supplier_code])
  end
end
