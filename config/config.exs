# =============================================================================
# Configuração Principal da Aplicação
# =============================================================================
#
# Este arquivo configura a aplicação como uma API REST pura.
# O frontend será desenvolvido separadamente (React, Vue, Next.js, etc.)

import Config

# =============================================================================
# Configuração Geral
# =============================================================================
config :loja_virtual,
  ecto_repos: [LojaVirtual.Repo],
  generators: [timestamp_type: :utc_datetime]

# =============================================================================
# Configuração do Endpoint (API REST)
# =============================================================================
config :loja_virtual, LojaVirtualWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  # Apenas JSON para erros (API pura)
  render_errors: [
    formats: [json: LojaVirtualWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LojaVirtual.PubSub

# =============================================================================
# Mailer (Email)
# =============================================================================
# By default it uses the "Local" adapter which stores the emails locally.
# For production, configure a different adapter at `config/runtime.exs`.
config :loja_virtual, LojaVirtual.Mailer, adapter: Swoosh.Adapters.Local

# =============================================================================
# Logger
# =============================================================================
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# =============================================================================
# JSON Library
# =============================================================================
config :phoenix, :json_library, Jason

# =============================================================================
# Import environment specific config
# This must remain at the bottom of this file.
# =============================================================================
import_config "#{config_env()}.exs"
