#!/bin/sh
# ==============================================================================
# Entrypoint - Script de inicialização do container
# ==============================================================================
# Este script roda automaticamente quando o container inicia.
# Ele garante que o banco está pronto e as migrations foram executadas.
# ==============================================================================

set -e

echo "🔄 Aguardando banco de dados ficar disponível..."

# Aguarda o PostgreSQL estar pronto
until pg_isready -h postgres -p 5432 -U postgres > /dev/null 2>&1; do
  echo "⏳ PostgreSQL ainda não está pronto..."
  sleep 2
done

echo "✅ PostgreSQL está pronto!"

echo "📦 Executando migrations..."
bin/loja_virtual eval "LojaVirtual.Release.migrate()"

echo "🌱 Executando seeds (se necessário)..."
bin/loja_virtual eval "LojaVirtual.Release.seed()"

echo "🚀 Iniciando servidor Phoenix..."
exec bin/loja_virtual start
