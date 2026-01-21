@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo  METATRADER5 INSTALLER FIX
echo ============================================================
echo.

REM ============================================================
REM 1. CEK PYTHON VERSION
REM ============================================================
for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
echo [INFO] Python Version: %PYTHON_VERSION%
echo.

REM ============================================================
REM 2. CEK & BUAT VENV
REM ============================================================
if not exist "venv\Scripts\activate.bat" (
    echo [INFO] Membuat virtual environment baru...
    python -m venv venv
    if !errorlevel! neq 0 (
        echo [ERROR] Gagal membuat venv
        pause
        exit /b 1
    )
)

REM ============================================================
REM 3. AKTIFKAN VENV
REM ============================================================
echo [INFO] Mengaktifkan venv...
call venv\Scripts\activate.bat

REM ============================================================
REM 4. UPGRADE PIP & TOOLS
REM ============================================================
echo [INFO] Upgrade pip, setuptools, dan wheel...
python -m pip install --upgrade pip setuptools wheel

REM ============================================================
REM 5. INSTALL METATRADER5 DENGAN CLEAN
REM ============================================================
echo.
echo [INFO] Uninstall MetaTrader5 lama (jika ada)...
pip uninstall MetaTrader5 -y

echo [INFO] Clear pip cache...
pip cache purge

echo [INFO] Install MetaTrader5 fresh...
pip install MetaTrader5 --no-cache-dir

if !errorlevel! neq 0 (
    echo [ERROR] MetaTrader5 install gagal
    echo [INFO] Trying alternative installation method...
    pip install --upgrade --force-reinstall MetaTrader5
    if !errorlevel! neq 0 (
        echo [ERROR] Alternative method juga gagal
        pause
        exit /b 1
    )
)

REM ============================================================
REM 6. INSTALL REQUIREMENTS LAINNYA
REM ============================================================
echo.
echo [INFO] Install requirements.txt...
pip install -r requirements.txt --upgrade

REM ============================================================
REM 7. VERIFIKASI INSTALLATION
REM ============================================================
echo.
echo [INFO] Verifikasi instalasi...
python -c "import MetaTrader5; print('[SUCCESS] MetaTrader5 versi: ' + MetaTrader5.__version__)"

if !errorlevel! neq 0 (
    echo [ERROR] MetaTrader5 masih tidak terinstall
    pause
    exit /b 1
)

python -c "import numpy, pandas, telegram; print('[SUCCESS] Semua module utama terinstall')"

echo.
echo ============================================================
echo [SUCCESS] INSTALASI SELESAI!
echo ============================================================
echo.
pause
