#!/bin/bash
# Setup the Loja Virtual project in WSL

set -e

echo "========================================="
echo "Setting up Loja Virtual Project"
echo "========================================="
echo ""

# Install dependencies
echo "[1/5] Installing dependencies..."
mix deps.get

# Compile dependencies (will compile snappyer with gcc)
echo "[2/5] Compiling dependencies..."
mix deps.compile

# Start Docker services
echo "[3/5] Starting Kafka and PostgreSQL..."
docker-compose up -d

# Wait for services
echo "Waiting for services to be ready..."
sleep 10

# Setup database
echo "[4/5] Setting up database..."
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs

# Compile application
echo "[5/5] Compiling application..."
mix compile

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Services:"
echo "  - Kafka UI:  http://localhost:8080"
echo "  - API:       http://localhost:4000"
echo ""
echo "To start the server:"
echo "  mix phx.server"
echo ""
echo "To test:"
echo "  curl http://localhost:4000/health"
echo ""
