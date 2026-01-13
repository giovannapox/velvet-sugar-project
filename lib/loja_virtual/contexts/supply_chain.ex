defmodule LojaVirtual.SupplyChain do
  @moduledoc """
  Context for supply chain management.

  Handles supplier shipments and stock replenishment.
  """

  import Ecto.Query
  alias LojaVirtual.Repo
  alias LojaVirtual.Schemas.SupplyShipment
  alias LojaVirtual.Kafka.{Topics, Producer}
  alias LojaVirtual.Inventory

  @doc """
  Creates a new supply shipment from a supplier.
  Publishes to supply.shipment.created topic.
  """
  def create_shipment(attrs) do
    %SupplyShipment{}
    |> SupplyShipment.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, shipment} ->
        publish_shipment_created(shipment)
        {:ok, shipment}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp publish_shipment_created(shipment) do
    event = %{
      id: shipment.id,
      supplier_name: shipment.supplier_name,
      supplier_email: shipment.supplier_email,
      items: shipment.items,
      status: "pending",
      created_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Producer.publish(Topics.supply_shipment_created(), shipment.id, event)
  end

  @doc """
  Approves a pending shipment and updates ingredient stock.
  Publishes to stock.replenished topic.
  """
  def approve_shipment(shipment_id, approved_by) do
    case get_shipment(shipment_id) do
      nil ->
        {:error, :not_found}

      %{status: :pending} = shipment ->
        do_approve_shipment(shipment, approved_by)

      %{status: status} ->
        {:error, {:invalid_status, status}}
    end
  end

  defp do_approve_shipment(shipment, approved_by) do
    now = DateTime.utc_now()

    Repo.transaction(fn ->
      # Update shipment status
      {:ok, updated_shipment} =
        shipment
        |> Ecto.Changeset.change(%{
          status: :approved,
          approved_by: approved_by,
          approved_at: now
        })
        |> Repo.update()

      # Replenish ingredient stock
      Inventory.replenish_ingredients(shipment.items)

      # Publish stock replenished event
      publish_stock_replenished(updated_shipment)

      updated_shipment
    end)
  end

  defp publish_stock_replenished(shipment) do
    event = %{
      shipment_id: shipment.id,
      items: shipment.items,
      approved_by: shipment.approved_by,
      approved_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    Producer.publish(Topics.stock_replenished(), shipment.id, event)

    # Also broadcast to admin dashboard
    Phoenix.PubSub.broadcast(
      LojaVirtual.PubSub,
      "admin:stock",
      {:stock_replenished, event}
    )
  end

  @doc """
  Rejects a pending shipment.
  """
  def reject_shipment(shipment_id, reason) do
    case get_shipment(shipment_id) do
      nil ->
        {:error, :not_found}

      %{status: :pending} = shipment ->
        shipment
        |> Ecto.Changeset.change(%{
          status: :rejected,
          rejection_reason: reason
        })
        |> Repo.update()

      %{status: status} ->
        {:error, {:invalid_status, status}}
    end
  end

  @doc "Gets a shipment by ID"
  def get_shipment(id), do: Repo.get(SupplyShipment, id)

  @doc "Lists shipments by status"
  def list_shipments_by_status(status) do
    SupplyShipment
    |> where([s], s.status == ^status)
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end

  @doc "Lists pending shipments (for admin approval)"
  def list_pending_shipments do
    list_shipments_by_status(:pending)
  end

  @doc "Lists all shipments"
  def list_shipments(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    SupplyShipment
    |> order_by([s], desc: s.inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end
end
