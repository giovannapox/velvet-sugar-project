@echo off
REM Compile the project with Visual Studio Build Tools

echo Compiling project...

REM Setup environment
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul 2>&1
set PATH=C:\Program Files\Erlang OTP\bin;C:\Program Files\Elixir\bin;%PATH%
set CC=cl.exe
set CXX=cl.exe

REM Compile
mix compile

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo Compilation successful!
    echo ========================================
) else (
    echo.
    echo ========================================
    echo Compilation failed! Check errors above.
    echo ========================================
)
