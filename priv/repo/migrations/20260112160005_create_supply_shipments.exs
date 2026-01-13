defmodule LojaVirtual.Repo.Migrations.CreateSupplyShipments do
  use Ecto.Migration

  def change do
    create table(:supply_shipments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string, default: "pending", null: false
      add :supplier_name, :string, null: false
      add :supplier_email, :string, null: false
      add :notes, :text

      # JSON array of items: [{ingredient_id, quantity, unit}]
      add :items, :jsonb, default: "[]", null: false

      # Approval tracking
      add :approved_by, :string
      add :approved_at, :utc_datetime
      add :rejection_reason, :text

      timestamps()
    end

    create index(:supply_shipments, [:status])
    create index(:supply_shipments, [:supplier_email])
  end
end
