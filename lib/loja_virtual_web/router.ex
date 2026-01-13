defmodule LojaVirtualWeb.Router do
  @moduledoc """
  =============================================================================
  Router - Definição de Rotas da API REST
  =============================================================================

  Este router define todas as rotas da API.
  O frontend JavaScript consumirá estes endpoints.

  📌 BASE URL: http://localhost:4000/api

  📌 ENDPOINTS DISPONÍVEIS:
  -------------------------
  POST   /api/orders              - Criar novo pedido
  GET    /api/orders              - Listar todos os pedidos
  GET    /api/orders/:id          - Buscar pedido por ID

  POST   /api/supply/shipments              - Criar remessa de suprimentos
  GET    /api/supply/shipments              - Listar remessas
  POST   /api/supply/shipments/:id/approve  - Aprovar remessa
  POST   /api/supply/shipments/:id/reject   - Rejeitar remessa

  GET    /api/inventory/products     - Listar produtos
  GET    /api/inventory/ingredients  - Listar ingredientes
  GET    /api/inventory/low-stock    - Listar itens com estoque baixo

  GET    /health  - Health check
  """
  use LojaVirtualWeb, :router

  # ============================================================================
  # Pipeline para API JSON
  # ============================================================================
  pipeline :api do
    plug :accepts, ["json"]
  end

  # ============================================================================
  # REST API Endpoints
  # ============================================================================
  scope "/api", LojaVirtualWeb.Api do
    pipe_through :api

    # Orders (Pedidos)
    post "/orders", OrderController, :create
    get "/orders/:id", OrderController, :show
    get "/orders", OrderController, :index

    # Supply Chain (Cadeia de Suprimentos)
    post "/supply/shipments", SupplyController, :create_shipment
    post "/supply/shipments/:id/approve", SupplyController, :approve
    post "/supply/shipments/:id/reject", SupplyController, :reject
    get "/supply/shipments", SupplyController, :list_shipments

    # Inventory (Inventário)
    get "/inventory/products", InventoryController, :list_products
    get "/inventory/ingredients", InventoryController, :list_ingredients
    get "/inventory/low-stock", InventoryController, :low_stock
  end

  # ============================================================================
  # Health Check - Para monitoramento e load balancers
  # ============================================================================
  scope "/", LojaVirtualWeb do
    pipe_through :api

    get "/health", HealthController, :check
  end
end
