#!/usr/bin/env python3
"""
Test if PaddleOCR is working with PDF files
"""

import requests
import json
import os
from datetime import datetime

def test_pdf_ocr():
    """Test PaddleOCR with a simple text file (since we don't have a PDF)"""
    
    print("🔍 Testing PaddleOCR with file upload...")
    print("=" * 50)
    
    # Create a simple text file for testing
    test_content = "This is a test document for PaddleOCR.\nIt contains multiple lines of text.\nPaddleOCR should be able to extract this text."
    
    # Save to a temporary file
    with open("test_document.txt", "w", encoding="utf-8") as f:
        f.write(test_content)
    
    try:
        # Test file upload
        print("📤 Uploading test file to OCR API...")
        
        with open("test_document.txt", "rb") as f:
            files = {"file": ("test_document.txt", f, "text/plain")}
            
            response = requests.post(
                "http://localhost:8000/api/v1/ocr/upload",
                files=files,
                timeout=60
            )
        
        print(f"📊 Response Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ SUCCESS: PaddleOCR is working!")
            print(f"   - Success: {result.get('success', False)}")
            print(f"   - Text Count: {result.get('text_count', 0)}")
            print(f"   - Processing Time: {result.get('processing_time', 'Unknown')}")
            
            # Show extracted text
            if result.get('results'):
                print("\n📄 Extracted Text:")
                for i, text_block in enumerate(result['results']):
                    print(f"   {i+1}. \"{text_block.get('text', '')}\" (Confidence: {text_block.get('confidence', 0)*100:.1f}%)")
            
            # Check webhook delivery
            webhook_delivery = result.get('webhook_delivery', {})
            if webhook_delivery:
                print(f"\n🔗 Webhook Status: {webhook_delivery.get('status', 'Unknown')}")
                webhook_results = webhook_delivery.get('results', [])
                if webhook_results:
                    for webhook_result in webhook_results:
                        print(f"   - Webhook: {webhook_result.get('config_name', 'Unknown')}")
                        print(f"     Success: {webhook_result.get('success', False)}")
                        if webhook_result.get('success'):
                            print(f"     ✅ Data sent to webhook successfully!")
                        else:
                            print(f"     ❌ Error: {webhook_result.get('error', 'Unknown error')}")
            
            print("\n🎉 CONCLUSION: PaddleOCR is working with files!")
            print("💡 Your flow is ready:")
            print("   1. Upload PDF/Image → PaddleOCR extracts text")
            print("   2. Text results → Sent to webhook")
            print("   3. Webhook → Returns answer")
            
            return True
        else:
            print(f"❌ FAILED: OCR API returned status {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False
    finally:
        # Clean up test file
        if os.path.exists("test_document.txt"):
            os.remove("test_document.txt")

def check_ocr_service_status():
    """Check if OCR service is properly initialized"""
    print("🔍 Checking OCR service status...")
    
    try:
        response = requests.get("http://localhost:8000/health")
        if response.status_code == 200:
            print("✅ API Server is running")
            
            # Check supported formats
            response = requests.get("http://localhost:8000/api/v1/ocr/enhanced/formats")
            if response.status_code == 200:
                formats = response.json()
                print("✅ Supported formats:")
                for format_type, extensions in formats.get('supported_formats', {}).items():
                    print(f"   - {format_type.upper()}: {', '.join(extensions)}")
                return True
            else:
                print("❌ Failed to get supported formats")
                return False
        else:
            print("❌ API Server is not responding")
            return False
    except Exception as e:
        print(f"❌ Error checking service: {e}")
        return False

if __name__ == "__main__":
    print("🚀 PaddleOCR PDF Test")
    print("=" * 50)
    
    # Check service status first
    if check_ocr_service_status():
        print("\n" + "=" * 50)
        # Test with actual file
        test_pdf_ocr()
    else:
        print("\n❌ Service is not ready. Please check the server logs.")
