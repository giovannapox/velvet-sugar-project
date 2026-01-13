@echo off
:: ==============================================================================
:: LOJA VIRTUAL - Iniciar API (Backend)
:: ==============================================================================
:: 
:: Basta dar DUPLO-CLIQUE neste arquivo!
::
:: Requisitos:
::   - Docker Desktop instalado e rodando
::
:: ==============================================================================

title Loja Virtual - API Backend

echo.
echo  ╔══════════════════════════════════════════════════════════════════╗
echo  ║                                                                  ║
echo  ║   🛒  LOJA VIRTUAL - API BACKEND                                 ║
echo  ║                                                                  ║
echo  ╚══════════════════════════════════════════════════════════════════╝
echo.

:: Verifica se Docker está instalado
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  ❌ ERRO: Docker nao esta instalado!
    echo.
    echo  Por favor, instale o Docker Desktop:
    echo  https://www.docker.com/products/docker-desktop
    echo.
    pause
    exit /b 1
)

:: Verifica se Docker está rodando
docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo  ❌ ERRO: Docker nao esta rodando!
    echo.
    echo  Por favor, abra o Docker Desktop e aguarde ele iniciar.
    echo.
    pause
    exit /b 1
)

echo  ✅ Docker detectado!
echo.
echo  📦 Iniciando containers...
echo  (Isso pode demorar alguns minutos na primeira vez)
echo.

:: Inicia os containers
docker-compose up --build

:: Se der erro
if %errorlevel% neq 0 (
    echo.
    echo  ❌ Ocorreu um erro ao iniciar os containers.
    echo  Verifique as mensagens acima.
    echo.
    pause
    exit /b 1
)

pause
