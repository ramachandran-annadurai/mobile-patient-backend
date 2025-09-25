#!/bin/bash

echo "============================================================"
echo "🧪 Medication OCR API Module Installer (Unix/Linux)"
echo "============================================================"
echo

echo "🔄 Checking Python installation..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed or not in PATH"
    echo "   Please install Python 3.8+ using your package manager"
    exit 1
fi

# Check Python version
python_version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
required_version="3.8"

if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo "❌ Python 3.8 or higher is required"
    echo "   Current version: $python_version"
    exit 1
fi

echo "✅ Python $python_version found"
echo

echo "🔄 Installing module in development mode..."
if ! python3 -m pip install -e .; then
    echo "❌ Module installation failed"
    exit 1
fi

echo "✅ Module installed successfully"
echo

echo "🔄 Installing development dependencies..."
if ! python3 -m pip install -e ".[dev]"; then
    echo "⚠️  Development dependencies failed, but core module is installed"
else
    echo "✅ Development dependencies installed"
fi

echo
echo "🎉 Installation completed successfully!"
echo
echo "📚 Next steps:"
echo "   1. Run the API: python3 -m medication"
echo "   2. Or use as module: from medication import app, EnhancedOCRService"
echo "   3. Run tests: pytest"
echo "   4. View API docs: http://localhost:8000/docs"
echo
