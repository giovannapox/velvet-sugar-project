@echo off
REM Setup and install all dependencies

echo ========================================
echo Installing dependencies...
echo ========================================

REM Setup environment
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul 2>&1
set PATH=C:\Program Files\Erlang OTP\bin;C:\Program Files\Elixir\bin;%PATH%
set CC=cl.exe
set CXX=cl.exe

REM Clean and get dependencies
echo Cleaning old dependencies...
rmdir /s /q deps 2>nul
rmdir /s /q _build 2>nul
del /q mix.lock 2>nul

echo.
echo Fetching dependencies...
mix deps.get

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Compiling dependencies...
    mix deps.compile
    
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo ========================================
        echo Dependencies installed successfully!
        echo ========================================
        echo.
        echo Next steps:
        echo   1. Start Kafka: docker-compose up -d
        echo   2. Setup database: mix ecto.setup
        echo   3. Start server: server.bat
    )
)
