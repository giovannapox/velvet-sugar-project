#!/bin/bash
# Setup script for Elixir/Phoenix with Kafka on WSL

set -e

echo "========================================="
echo "Installing Elixir/Phoenix with Kafka"
echo "========================================="
echo ""

# Update system
echo "[1/6] Updating system packages..."
sudo apt update
sudo apt upgrade -y

# Install dependencies
echo "[2/6] Installing dependencies..."
sudo apt install -y curl git build-essential autoconf m4 libncurses5-dev \
    libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev \
    libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop \
    libxml2-utils libncurses-dev openjdk-11-jdk inotify-tools

# Install Erlang
echo "[3/6] Installing Erlang..."
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt update
sudo apt install -y esl-erlang

# Install Elixir
echo "[4/6] Installing Elixir..."
sudo apt install -y elixir

# Install Hex and Phoenix
echo "[5/6] Installing Hex and Phoenix..."
mix local.hex --force
mix local.rebar --force
mix archive.install hex phx_new --force

# Install Docker (if not already installed)
echo "[6/6] Checking Docker..."
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "Docker installed. You may need to logout and login again."
fi

echo ""
echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "Elixir version:"
elixir --version
echo ""
echo "Next steps:"
echo "  1. cd ~/loja_virtual"
echo "  2. ./setup-project.sh"
echo ""
