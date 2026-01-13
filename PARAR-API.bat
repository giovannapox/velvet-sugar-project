@echo off
:: ==============================================================================
:: LOJA VIRTUAL - Parar API
:: ==============================================================================

title Loja Virtual - Parando API

echo.
echo  🛑 Parando todos os containers...
echo.

docker-compose down

echo.
echo  ✅ API parada com sucesso!
echo.

pause
