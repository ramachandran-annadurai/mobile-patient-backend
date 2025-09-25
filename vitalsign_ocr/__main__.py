"""
Main entry point for the medication-ocr-api package.

This allows the package to be run as a module:
    python -m medication

Or directly:
    python __main__.py
"""

import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def main():
    """Main entry point for the medication OCR API."""
    try:
        from medication.app.main import main as app_main
        app_main()
    except ImportError as e:
        print(f"Error importing medication package: {e}")
        print("Make sure you have installed the package correctly.")
        sys.exit(1)
    except Exception as e:
        print(f"Error running medication OCR API: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
