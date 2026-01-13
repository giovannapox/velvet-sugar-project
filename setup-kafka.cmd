@echo off
SETLOCAL

REM Full setup and test for Kafka integration

echo ========================================
echo Kafka Integration - Full Setup
echo ========================================
echo.

REM Step 1: Setup environment
echo [1/5] Setting up Visual Studio environment...
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\VsDevCmd.bat" -arch=x64 >nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Visual Studio Build Tools not found!
    echo Please install: https://visualstudio.microsoft.com/downloads/
    exit /b 1
)

set PATH=C:\Program Files\Erlang OTP\bin;C:\Program Files\Elixir\bin;%PATH%

echo [2/5] Compiling project...
mix compile
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Compilation failed!
    exit /b 1
)

echo.
echo [3/5] Checking Kafka/PostgreSQL...
docker ps | findstr "loja_virtual_kafka" >nul
if %ERRORLEVEL% NEQ 0 (
    echo Kafka not running. Starting Docker containers...
    docker-compose up -d
    timeout /t 10 >nul
)

echo.
echo [4/5] Setting up database...
mix ecto.create >nul 2>&1
mix ecto.migrate
mix run priv/repo/seeds.exs

echo.
echo [5/5] Testing Kafka connection...
curl -s http://localhost:8080 >nul
if %ERRORLEVEL% EQU 0 (
    echo Kafka UI available at: http://localhost:8080
)

echo.
echo ========================================
echo Setup Complete!
echo ========================================
echo.
echo To start the server:
echo   server.bat
echo.
echo To test the API:
echo   curl http://localhost:4000/health
echo.

ENDLOCAL
