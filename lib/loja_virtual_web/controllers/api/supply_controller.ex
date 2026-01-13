defmodule LojaVirtualWeb.Api.SupplyController do
  @moduledoc """
  API controller for supply chain management.

  Endpoints:
  - POST /api/supply/shipments - Supplier creates a shipment
  - POST /api/supply/shipments/:id/approve - Admin approves shipment
  - POST /api/supply/shipments/:id/reject - Admin rejects shipment
  - GET /api/supply/shipments - List shipments
  """
  use LojaVirtualWeb, :controller

  alias LojaVirtual.SupplyChain

  action_fallback LojaVirtualWeb.FallbackController

  @doc """
  Creates a new supply shipment (Supplier action).
  Publishes to supply.shipment.created topic.

  ## Request Body
  ```json
  {
    "supplier_name": "Fornecedor ABC",
    "supplier_email": "fornecedor@email.com",
    "notes": "Optional notes",
    "items": [
      {"ingredient_id": "uuid", "quantity": 10}
    ]
  }
  ```
  """
  def create_shipment(conn, params) do
    shipment_attrs = %{
      supplier_name: params["supplier_name"],
      supplier_email: params["supplier_email"],
      notes: params["notes"],
      items: params["items"]
    }

    case SupplyChain.create_shipment(shipment_attrs) do
      {:ok, shipment} ->
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          shipment: %{
            id: shipment.id,
            status: shipment.status,
            supplier_name: shipment.supplier_name,
            items_count: length(shipment.items),
            message: "Shipment created and sent to admin for approval"
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          errors: format_errors(changeset)
        })
    end
  end

  @doc """
  Approves a pending shipment (Admin action).
  Updates ingredient stock and publishes to stock.replenished topic.
  """
  def approve(conn, %{"id" => shipment_id} = params) do
    approved_by = params["approved_by"] || "admin"

    case SupplyChain.approve_shipment(shipment_id, approved_by) do
      {:ok, shipment} ->
        conn
        |> json(%{
          success: true,
          message: "Shipment approved. Stock has been updated.",
          shipment: %{
            id: shipment.id,
            status: shipment.status,
            approved_by: shipment.approved_by,
            approved_at: shipment.approved_at
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: "Shipment not found"})

      {:error, {:invalid_status, status}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: "Cannot approve shipment with status: #{status}"
        })

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  @doc """
  Rejects a pending shipment (Admin action).
  """
  def reject(conn, %{"id" => shipment_id} = params) do
    reason = params["reason"] || "Rejected by admin"

    case SupplyChain.reject_shipment(shipment_id, reason) do
      {:ok, shipment} ->
        conn
        |> json(%{
          success: true,
          message: "Shipment rejected.",
          shipment: %{
            id: shipment.id,
            status: shipment.status,
            rejection_reason: shipment.rejection_reason
          }
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{success: false, error: "Shipment not found"})

      {:error, {:invalid_status, status}} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: "Cannot reject shipment with status: #{status}"
        })

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{success: false, error: inspect(reason)})
    end
  end

  @doc "Lists shipments with optional status filter"
  def list_shipments(conn, params) do
    shipments = case params["status"] do
      nil -> SupplyChain.list_shipments()
      status -> SupplyChain.list_shipments_by_status(String.to_existing_atom(status))
    end

    conn
    |> json(%{
      success: true,
      shipments: Enum.map(shipments, fn s ->
        %{
          id: s.id,
          status: s.status,
          supplier_name: s.supplier_name,
          supplier_email: s.supplier_email,
          items_count: length(s.items),
          created_at: s.inserted_at,
          approved_at: s.approved_at
        }
      end)
    })
  end

  # Private helpers

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
