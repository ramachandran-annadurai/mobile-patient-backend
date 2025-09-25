@echo off
echo ============================================================
echo 🧪 Medication OCR API Module Installer (Windows)
echo ============================================================
echo.

echo 🔄 Checking Python installation...
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed or not in PATH
    echo    Please install Python 3.8+ from https://python.org
    pause
    exit /b 1
)

echo ✅ Python found
echo.

echo 🔄 Installing module in development mode...
pip install -e .
if errorlevel 1 (
    echo ❌ Module installation failed
    pause
    exit /b 1
)

echo ✅ Module installed successfully
echo.

echo 🔄 Installing development dependencies...
pip install -e .[dev]
if errorlevel 1 (
    echo ⚠️  Development dependencies failed, but core module is installed
) else (
    echo ✅ Development dependencies installed
)

echo.
echo 🎉 Installation completed successfully!
echo.
echo 📚 Next steps:
echo    1. Run the API: python -m medication
echo    2. Or use as module: from medication import app, EnhancedOCRService
echo    3. Run tests: pytest
echo    4. View API docs: http://localhost:8000/docs
echo.
pause
