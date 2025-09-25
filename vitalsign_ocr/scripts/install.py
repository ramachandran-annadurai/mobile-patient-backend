#!/usr/bin/env python3
"""
Simple installation script for Medication OCR API Module
"""

import subprocess
import sys
import os

def run_command(command, description):
    """Run a command and handle errors"""
    print(f"🔄 {description}...")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✅ {description} completed successfully")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} failed:")
        print(f"   Error: {e.stderr}")
        return False

def check_python_version():
    """Check if Python version is compatible"""
    if sys.version_info < (3, 8):
        print("❌ Python 3.8 or higher is required")
        print(f"   Current version: {sys.version}")
        return False
    print(f"✅ Python version {sys.version.split()[0]} is compatible")
    return True

def install_module():
    """Install the module in development mode"""
    print("🚀 Installing Medication OCR API Module...")
    
    # Check Python version
    if not check_python_version():
        return False
    
    # Install in development mode
    if not run_command("pip install -e .", "Installing module in development mode"):
        return False
    
    # Install development dependencies
    if not run_command("pip install -e .[dev]", "Installing development dependencies"):
        print("⚠️  Development dependencies installation failed, but core module is installed")
    
    print("\n🎉 Installation completed successfully!")
    print("\n📚 Next steps:")
    print("   1. Run the API: python -m medication")
    print("   2. Or use as module: from medication import app, EnhancedOCRService")
    print("   3. Run tests: pytest")
    print("   4. View API docs: http://localhost:8000/docs")
    
    return True

def main():
    """Main installation function"""
    print("=" * 60)
    print("🧪 Medication OCR API Module Installer")
    print("=" * 60)
    
    if not install_module():
        print("\n❌ Installation failed. Please check the errors above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
