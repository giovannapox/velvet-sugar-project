defmodule LojaVirtual.Schemas.SupplyShipment do
  @moduledoc """
  Schema for supplier shipments.

  Tracks shipments from suppliers that need admin approval
  before updating ingredient stock.

  Lifecycle:
  pending -> approved (stock updated) OR rejected
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @statuses [:pending, :approved, :rejected]

  schema "supply_shipments" do
    field :status, Ecto.Enum, values: @statuses, default: :pending
    field :supplier_name, :string
    field :supplier_email, :string
    field :notes, :string

    # JSON field for shipment items
    # Format: [%{ingredient_id: uuid, quantity: decimal, unit: string}]
    field :items, {:array, :map}, default: []

    # Approval tracking
    field :approved_by, :string
    field :approved_at, :utc_datetime
    field :rejection_reason, :string

    timestamps()
  end

  def changeset(shipment, attrs) do
    shipment
    |> cast(attrs, [:status, :supplier_name, :supplier_email, :notes, :items,
                    :approved_by, :approved_at, :rejection_reason])
    |> validate_required([:supplier_name, :supplier_email, :items])
    |> validate_format(:supplier_email, ~r/@/)
    |> validate_items()
  end

  defp validate_items(changeset) do
    case get_field(changeset, :items) do
      nil -> changeset
      [] -> add_error(changeset, :items, "must have at least one item")
      items when is_list(items) ->
        if Enum.all?(items, &valid_item?/1) do
          changeset
        else
          add_error(changeset, :items, "all items must have ingredient_id and quantity")
        end
      _ -> add_error(changeset, :items, "must be a list")
    end
  end

  defp valid_item?(%{"ingredient_id" => id, "quantity" => qty})
       when is_binary(id) and is_number(qty) and qty > 0, do: true
  defp valid_item?(%{ingredient_id: id, quantity: qty})
       when is_binary(id) and is_number(qty) and qty > 0, do: true
  defp valid_item?(_), do: false

  def statuses, do: @statuses
end
