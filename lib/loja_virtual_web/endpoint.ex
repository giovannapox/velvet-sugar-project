defmodule LojaVirtualWeb.Endpoint do
  @moduledoc """
  =============================================================================
  Endpoint HTTP - API REST
  =============================================================================

  O Endpoint é o ponto de entrada de todas as requisições HTTP.
  Configurado para servir uma API REST pura com suporte a CORS.

  📌 CORS (Cross-Origin Resource Sharing):
  ----------------------------------------
  Habilitado para permitir que frontends em diferentes domínios
  (ex: localhost:3000 para React) consumam esta API.
  """
  use Phoenix.Endpoint, otp_app: :loja_virtual

  # ============================================================================
  # CORS - Cross-Origin Resource Sharing
  # ============================================================================
  # Permite que frontends em outros domínios acessem a API
  # Em produção, configure origins específicas em vez de "*"
  plug CORSPlug,
    origin: ["http://localhost:3000", "http://localhost:5173", "http://127.0.0.1:3000"],
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    headers: ["Authorization", "Content-Type", "Accept", "Origin", "X-Requested-With"]

  # ============================================================================
  # Request Handling
  # ============================================================================

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # Parser para requisições JSON
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # ============================================================================
  # Code Reloader (apenas desenvolvimento)
  # ============================================================================
  if code_reloading? do
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :loja_virtual
  end

  # ============================================================================
  # Dashboard (apenas desenvolvimento)
  # ============================================================================
  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  # ============================================================================
  # Router - Processa as rotas definidas
  # ============================================================================
  plug LojaVirtualWeb.Router
end
