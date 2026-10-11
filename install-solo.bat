@echo off
:: ============================================================
::  Axiom Zeta Sentinel SOLO - One-Click Installer (Windows)
::
::  Double-click this file. That's it.
::
::  What it does:
::    1. Checks for Python 3.10+ and Rust
::    2. Builds the Rust extension (maturin)
::    3. Installs Python dependencies
::    4. Generates a secure API key
::    5. Launches the Sentinel gateway
::
::  First run takes 10-20 minutes (mostly compiling Rust).
::  Every launch after that is instant.
:: ============================================================
setlocal EnableDelayedExpansion

title Axiom Zeta Sentinel SOLO - Installer

set "DRIVE=%~dp0"
set "APP_DIR=!DRIVE!solo"

echo.
echo  ============================================================
echo   AXIOM ZETA SENTINEL SOLO - One-Click Installer
echo  ============================================================
echo.
echo  First run takes 10-20 minutes (compiling + installing).
echo  It runs unattended - walk away and come back.
echo.

:: ── Step 0: Python ──────────────────────────────────────────
echo [0/4] Checking Python...
where python >nul 2>nul
if !ERRORLEVEL! NEQ 0 (
    echo.
    echo  ERROR: Python 3.10 or newer is not installed.
    echo  Get it from https://www.python.org/downloads/
    echo  (Tip: tick "Add python.exe to PATH" during setup.)
    pause
    exit /b 1
)
python -c "import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul
if !ERRORLEVEL! NEQ 0 (
    echo  ERROR: Python 3.10 or newer is required.
    pause
    exit /b 1
)
echo  Python found.

:: ── Step 1: Rust ────────────────────────────────────────────
echo.
echo [1/4] Checking Rust...
where cargo >nul 2>nul
if !ERRORLEVEL! NEQ 0 (
    echo  Rust not found. Installing (internet required)...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://win.rustup.rs/x86_64' -OutFile $env:TEMP\rustup-init.exe"
    "%TEMP%\rustup-init.exe" -y --default-toolchain stable
    set "PATH=%USERPROFILE%\.cargo\bin;!PATH!"
)
where cargo >nul 2>nul
if !ERRORLEVEL! NEQ 0 (
    echo  ERROR: Rust installation failed. Install from https://rustup.rs/
    pause
    exit /b 1
)
echo  Rust found.

:: ── Step 2: Build + Install ─────────────────────────────────
echo.
echo [2/4] Building Sentinel (this is the long step)...
cd /d "!APP_DIR!"

if not exist ".venv" (
    python -m venv .venv
)
call .venv\Scripts\activate.bat

echo  Installing build tools...
pip install -q -U pip maturin

if exist "rust" (
    echo  Compiling Rust extension (5-15 minutes)...
    cd rust
    maturin develop --release
    cd ..
)

echo  Installing Python dependencies...
if exist "requirements-dev.txt" pip install -q -r requirements-dev.txt
pip install -q -e .

:: ── Step 3: API Key ─────────────────────────────────────────
echo.
echo [3/4] Setting up API key...
if not exist ".env" (
    python -c "import secrets; print('GATEWAY_API_KEY=' + secrets.token_urlsafe(32))" > .env
    echo  Generated secure API key in .env
) else (
    echo  Using existing .env
)

:: ── Step 4: Launch ──────────────────────────────────────────
echo.
echo [4/4] Launching Sentinel SOLO...
echo.
echo  ============================================================
echo   SENTINEL SOLO IS RUNNING
echo.
echo   API: http://localhost:8000
echo   Health: http://localhost:8000/v1/health
echo.
for /f "tokens=2 delims==" %%k in ('findstr GATEWAY_API_KEY .env') do set "KEY=%%k"
echo   Your API key: !KEY!
echo   (Save this - you'll need it for API requests)
echo.
echo   Example:
echo   curl -X POST http://localhost:8000/v1/stabilize ^
echo     -H "X-API-Key: !KEY!" ^
echo     -H "Content-Type: application/json" ^
echo     -d "{\"tenant_id\":\"acme\",\"text\":\"hello\"}"
echo  ============================================================
echo.
set "GATEWAY_API_KEY=!KEY!"
uvicorn gateway.main:app --port 8000
pause
