@echo off
REM Setup script for Elixir/Phoenix with Kafka (requires Visual Studio Build Tools)

echo ========================================
echo Setting up development environment...
echo ========================================

REM Add Visual Studio Build Tools to PATH
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64

REM Add Elixir and Erlang to PATH
set PATH=C:\Program Files\Erlang OTP\bin;C:\Program Files\Elixir\bin;%PATH%

REM Set compiler environment variables
set CC=cl.exe
set CXX=cl.exe

echo Environment configured successfully!
echo.
echo Available commands:
echo   compile.bat  - Compile the project
echo   server.bat   - Start Phoenix server
echo   shell.bat    - Start IEx shell
echo.

