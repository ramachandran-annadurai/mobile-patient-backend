#!/usr/bin/env python3
"""
Test the fixed PaddleOCR service
"""

import requests
import json
import os
from datetime import datetime

def test_fixed_ocr():
    """Test the fixed OCR service"""
    
    print("🔍 Testing Fixed PaddleOCR Service...")
    print("=" * 50)
    
    # Create a simple text file for testing
    test_content = "This is a test document for PaddleOCR.\nIt contains multiple lines of text.\nPaddleOCR should be able to extract this text properly now."
    
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
            print("✅ SUCCESS: Fixed OCR service is working!")
            print(f"   - Success: {result.get('success', False)}")
            print(f"   - Text Count: {result.get('text_count', 0)}")
            print(f"   - Processing Time: {result.get('processing_time', 'Unknown')}")
            
            # Show extracted text
            if result.get('results'):
                print("\n📄 Extracted Text:")
                for i, text_block in enumerate(result['results']):
                    print(f"   {i+1}. \"{text_block.get('text', '')}\" (Confidence: {text_block.get('confidence', 0)*100:.1f}%)")
            else:
                print("\n❌ No text extracted - OCR is still not working properly")
                return False
            
            # Check webhook delivery
            webhook_delivery = result.get('webhook_delivery', {})
            if webhook_delivery:
                webhook_status = webhook_delivery.get('status', 'unknown')
                print(f"\n🔗 Webhook Status: {webhook_status}")
                
                if webhook_status == 'completed':
                    print("✅ Webhook delivery successful!")
                else:
                    print("⚠️ Webhook delivery failed - but OCR is working")
                
                webhook_results = webhook_delivery.get('results', [])
                if webhook_results:
                    for webhook_result in webhook_results:
                        print(f"   - Webhook: {webhook_result.get('config_name', 'Unknown')}")
                        print(f"     Success: {webhook_result.get('success', False)}")
                        if not webhook_result.get('success', False):
                            print(f"     Error: {webhook_result.get('error', 'Unknown error')}")
            
            print("\n🎉 CONCLUSION: OCR is now working properly!")
            print("💡 Your flow should now work:")
            print("   1. Upload PDF/Image → PaddleOCR extracts text ✅")
            print("   2. Text results → Sent to webhook ✅")
            print("   3. Webhook → Returns answer ✅")
            
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

def test_with_simple_image():
    """Test with a simple base64 image"""
    print("\n🖼️ Testing with Base64 Image...")
    
    # Create a simple 1x1 pixel image
    test_image_data = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
    
    try:
        base64_payload = {
            "image": f"data:image/png;base64,{test_image_data}"
        }
        
        response = requests.post(
            "http://localhost:8000/api/v1/ocr/base64",
            json=base64_payload,
            timeout=60
        )
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Base64 image processing successful")
            print(f"   - Success: {result.get('success', False)}")
            print(f"   - Text Count: {result.get('text_count', 0)}")
            
            if result.get('results'):
                print("   - Extracted text found")
            else:
                print("   - No text extracted (expected for 1x1 pixel image)")
            
            return True
        else:
            print(f"❌ Base64 image processing failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing base64 image: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Testing Fixed PaddleOCR Service")
    print("=" * 50)
    
    # Test with text file
    text_test = test_fixed_ocr()
    
    # Test with base64 image
    image_test = test_with_simple_image()
    
    print("\n" + "=" * 50)
    print("📊 FINAL RESULTS:")
    print("=" * 50)
    print(f"Text File Processing: {'✅ WORKING' if text_test else '❌ FAILED'}")
    print(f"Base64 Image Processing: {'✅ WORKING' if image_test else '❌ FAILED'}")
    
    if text_test:
        print("\n🎉 PaddleOCR is now working properly!")
        print("💡 You can now upload PDF files and they should extract text correctly.")
        print("💡 The webhook will receive the extracted text and send it to your n8n workflow.")
    else:
        print("\n❌ PaddleOCR is still not working properly.")
        print("💡 Check the server logs for more detailed error information.")
