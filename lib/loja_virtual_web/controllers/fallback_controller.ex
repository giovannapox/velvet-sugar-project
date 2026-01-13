defmodule LojaVirtualWeb.FallbackController do
  @moduledoc """
  Fallback controller for handling errors.
  """
  use LojaVirtualWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: LojaVirtualWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: LojaVirtualWeb.ErrorJSON)
    |> render(:"401")
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: LojaVirtualWeb.ErrorJSON)
    |> render(:error, changeset: changeset)
  end
end
