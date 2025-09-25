#!/usr/bin/env python3
"""
Test PaddleOCR directly to see if it's working
"""

import sys
import os

def test_paddleocr_import():
    """Test if PaddleOCR can be imported"""
    print("🔍 Testing PaddleOCR Import...")
    try:
        from paddleocr import PaddleOCR
        print("✅ PaddleOCR imported successfully")
        return True
    except ImportError as e:
        print(f"❌ Failed to import PaddleOCR: {e}")
        return False
    except Exception as e:
        print(f"❌ Error importing PaddleOCR: {e}")
        return False

def test_paddleocr_initialization():
    """Test if PaddleOCR can be initialized"""
    print("\n🔍 Testing PaddleOCR Initialization...")
    try:
        from paddleocr import PaddleOCR
        print("   Initializing PaddleOCR...")
        ocr = PaddleOCR(use_angle_cls=True, lang='en', show_log=False)
        print("✅ PaddleOCR initialized successfully")
        return ocr
    except Exception as e:
        print(f"❌ Failed to initialize PaddleOCR: {e}")
        return None

def test_paddleocr_with_image():
    """Test PaddleOCR with a simple image"""
    print("\n🔍 Testing PaddleOCR with Image...")
    try:
        from paddleocr import PaddleOCR
        from PIL import Image, ImageDraw, ImageFont
        import numpy as np
        
        # Create a simple test image with text
        print("   Creating test image...")
        img = Image.new('RGB', (400, 100), color='white')
        draw = ImageDraw.Draw(img)
        
        # Try to use a default font
        try:
            font = ImageFont.truetype("arial.ttf", 20)
        except:
            font = ImageFont.load_default()
        
        draw.text((10, 30), "Test OCR Text", fill='black', font=font)
        
        # Convert to numpy array
        img_array = np.array(img)
        
        # Initialize PaddleOCR
        print("   Initializing PaddleOCR...")
        ocr = PaddleOCR(use_angle_cls=True, lang='en', show_log=False)
        
        # Process image
        print("   Processing image with PaddleOCR...")
        result = ocr.ocr(img_array, cls=True)
        
        if result and result[0]:
            print("✅ PaddleOCR processed image successfully")
            print("   Extracted text:")
            for line in result[0]:
                if line:
                    text = line[1][0]
                    confidence = line[1][1]
                    print(f"     - '{text}' (Confidence: {confidence:.2f})")
            return True
        else:
            print("❌ PaddleOCR returned no results")
            return False
            
    except Exception as e:
        print(f"❌ Error testing PaddleOCR with image: {e}")
        return False

def test_dependencies():
    """Test if all required dependencies are available"""
    print("🔍 Testing Dependencies...")
    
    dependencies = [
        ('PIL', 'Pillow'),
        ('cv2', 'opencv-python'),
        ('numpy', 'numpy'),
        ('fitz', 'PyMuPDF'),
        ('PyPDF2', 'PyPDF2')
    ]
    
    all_good = True
    for module, package in dependencies:
        try:
            __import__(module)
            print(f"✅ {package} is available")
        except ImportError:
            print(f"❌ {package} is missing")
            all_good = False
    
    return all_good

if __name__ == "__main__":
    print("🚀 PaddleOCR Direct Test")
    print("=" * 50)
    
    # Test dependencies
    deps_ok = test_dependencies()
    
    if deps_ok:
        # Test PaddleOCR import
        import_ok = test_paddleocr_import()
        
        if import_ok:
            # Test initialization
            ocr = test_paddleocr_initialization()
            
            if ocr:
                # Test with image
                test_paddleocr_with_image()
    
    print("\n" + "=" * 50)
    print("📊 SUMMARY:")
    print("=" * 50)
    print(f"Dependencies: {'✅ OK' if deps_ok else '❌ MISSING'}")
    print(f"PaddleOCR Import: {'✅ OK' if 'import_ok' in locals() and import_ok else '❌ FAILED'}")
    print(f"PaddleOCR Init: {'✅ OK' if 'ocr' in locals() and ocr else '❌ FAILED'}")
    
    if not deps_ok:
        print("\n💡 SOLUTION: Install missing dependencies:")
        print("   pip install paddlepaddle paddleocr pillow opencv-python numpy PyMuPDF PyPDF2")
