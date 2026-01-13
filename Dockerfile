# ==============================================================================
# Dockerfile - Loja Virtual API
# ==============================================================================
# Este arquivo define como construir a aplicação Elixir em um container Docker.
# Sua namorada NÃO precisa entender isso - só precisa rodar docker-compose up!
# ==============================================================================

# ------------------------------------------------------------------------------
# STAGE 1: Build (Compilação)
# ------------------------------------------------------------------------------
FROM elixir:1.17-alpine AS builder

# Instala dependências do sistema necessárias para compilar
RUN apk add --no-cache \
    build-base \
    git \
    npm \
    python3

# Define variáveis de ambiente para build
ENV MIX_ENV=prod

# Cria diretório da aplicação
WORKDIR /app

# Instala ferramentas Hex e Rebar (gerenciadores de pacotes Elixir)
RUN mix local.hex --force && \
    mix local.rebar --force

# Copia arquivos de dependências primeiro (para cache do Docker)
COPY mix.exs mix.lock ./
COPY config config

# Instala dependências de produção
RUN mix deps.get --only prod

# Copia o resto do código
COPY lib lib
COPY priv priv

# Compila a aplicação
RUN mix compile

# Cria o release (versão otimizada para produção)
RUN mix release

# ------------------------------------------------------------------------------
# STAGE 2: Runtime (Execução)
# ------------------------------------------------------------------------------
FROM alpine:3.19 AS runtime

# Instala dependências mínimas para rodar Elixir
RUN apk add --no-cache \
    libstdc++ \
    openssl \
    ncurses-libs \
    libgcc \
    postgresql-client

WORKDIR /app

# Copia o release do stage de build
COPY --from=builder /app/_build/prod/rel/loja_virtual ./

# Copia o entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Cria pasta de uploads
RUN mkdir -p /app/lib/loja_virtual-0.1.0/priv/static/uploads/products

# Variáveis de ambiente
ENV HOME=/app
ENV MIX_ENV=prod
ENV PHX_SERVER=true

# Porta da aplicação
EXPOSE 4000

# Comando para iniciar (usa o entrypoint que roda migrations)
ENTRYPOINT ["/app/entrypoint.sh"]
