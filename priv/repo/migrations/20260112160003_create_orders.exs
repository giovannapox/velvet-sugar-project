defmodule LojaVirtual.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :status, :string, default: "new", null: false
      add :type, :string, null: false
      add :total, :decimal, precision: 10, scale: 2, null: false
      add :customer_email, :string, null: false
      add :customer_name, :string, null: false
      add :delivery_address, :text, null: false

      # Timestamp tracking
      add :paid_at, :utc_datetime
      add :shipped_at, :utc_datetime
      add :delivered_at, :utc_datetime

      timestamps()
    end

    create index(:orders, [:status])
    create index(:orders, [:type])
    create index(:orders, [:customer_email])
  end
end
