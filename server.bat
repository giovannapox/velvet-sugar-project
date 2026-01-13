@echo off
REM Start Phoenix server with Kafka support

echo Starting Phoenix server...
echo Make sure Kafka is running: docker-compose up -d
echo.

REM Setup environment
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul 2>&1
set PATH=C:\Program Files\Erlang OTP\bin;C:\Program Files\Elixir\bin;%PATH%
set CC=cl.exe
set CXX=cl.exe

REM Start server
mix phx.server
