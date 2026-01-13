import Config

# =============================================================================
# Configuração do Banco de Dados
# =============================================================================
# Usa variável de ambiente DATABASE_HOST ou fallback para localhost
# No Docker, DATABASE_HOST será "postgres" (nome do serviço)
db_host = System.get_env("DATABASE_HOST", "localhost")

config :loja_virtual, LojaVirtual.Repo,
  username: "postgres",
  password: "postgres",
  hostname: db_host,
  database: "loja_virtual_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# =============================================================================
# Configuração do Endpoint para Desenvolvimento (API REST)
# =============================================================================
config :loja_virtual, LojaVirtualWeb.Endpoint,
  # Aceita conexões de qualquer IP (necessário para Docker)
  http: [ip: {0, 0, 0, 0}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "/EUGnLo89IHHIIchN/3O8i/MeI6VDQbJXSYpvd+0hBeDmIkNGHR4tyFOLyNzhVhg"

# =============================================================================
# Live Reload - Apenas para arquivos Elixir (sem assets)
# =============================================================================
config :loja_virtual, LojaVirtualWeb.Endpoint,
  live_reload: [
    web_console_logger: true,
    patterns: [
      ~r"priv/gettext/.*\.po$",
      ~r"lib/loja_virtual_web/router\.ex$",
      ~r"lib/loja_virtual_web/controllers/.*\.ex$"
    ]
  ]

# Enable dev routes for dashboard
config :loja_virtual, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :default_formatter, format: "[$level] $message\n"

# Set a higher stacktrace during development
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# Disable swoosh api client
config :swoosh, :api_client, false

# =============================================================================
# Kafka Configuration
# =============================================================================
kafka_host = System.get_env("KAFKA_HOST", "localhost")

config :loja_virtual, start_kafka: System.get_env("START_KAFKA") == "true"

config :loja_virtual, :kafka,
  hosts: [{kafka_host, 9092}],
  client_id: :loja_virtual
