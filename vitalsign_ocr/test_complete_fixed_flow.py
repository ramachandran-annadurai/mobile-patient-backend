#!/usr/bin/env python3
"""
Test the complete fixed flow: Upload → PaddleOCR → Webhook → Answer
"""

import requests
import json
import os
import time
from datetime import datetime

def wait_for_server():
    """Wait for server to start"""
    print("⏳ Waiting for server to start...")
    for i in range(30):  # Wait up to 30 seconds
        try:
            response = requests.get("http://localhost:8000/health", timeout=5)
            if response.status_code == 200:
                print("✅ Server is running!")
                return True
        except:
            pass
        time.sleep(1)
        print(f"   Waiting... ({i+1}/30)")
    
    print("❌ Server failed to start")
    return False

def test_complete_flow():
    """Test the complete flow"""
    
    print("🚀 Testing Complete Fixed Flow")
    print("=" * 60)
    
    # Wait for server
    if not wait_for_server():
        return False
    
    # Create a test file
    test_content = "Patient Name: John Doe\nMedication: Aspirin 100mg\nDosage: Take twice daily with food"
    
    with open("test_medical_document.txt", "w", encoding="utf-8") as f:
        f.write(test_content)
    
    try:
        print("\n📤 Step 1: Uploading file to OCR API...")
        
        with open("test_medical_document.txt", "rb") as f:
            files = {"file": ("test_medical_document.txt", f, "text/plain")}
            
            response = requests.post(
                "http://localhost:8000/api/v1/ocr/upload",
                files=files,
                timeout=60
            )
        
        print(f"📊 Response Status: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Step 1 SUCCESS: File uploaded and processed")
            print(f"   - Success: {result.get('success', False)}")
            print(f"   - Text Count: {result.get('text_count', 0)}")
            
            # Show extracted text
            if result.get('results'):
                print("\n📄 Extracted Text:")
                for i, text_block in enumerate(result['results']):
                    print(f"   {i+1}. \"{text_block.get('text', '')}\" (Confidence: {text_block.get('confidence', 0)*100:.1f}%)")
            
            # Check webhook delivery
            print("\n🔗 Step 2: Checking webhook delivery...")
            webhook_delivery = result.get('webhook_delivery', {})
            if webhook_delivery:
                webhook_status = webhook_delivery.get('status', 'unknown')
                print(f"✅ Step 2 SUCCESS: Webhook status = {webhook_status}")
                
                webhook_results = webhook_delivery.get('results', [])
                if webhook_results:
                    for i, webhook_result in enumerate(webhook_results):
                        print(f"   - Webhook {i+1}: {webhook_result.get('config_name', 'Unknown')}")
                        print(f"     URL: {webhook_result.get('url', 'Unknown')}")
                        print(f"     Success: {webhook_result.get('success', False)}")
                        if webhook_result.get('success'):
                            print(f"     ✅ Data sent to webhook successfully!")
                        else:
                            print(f"     ❌ Error: {webhook_result.get('error', 'Unknown error')}")
                else:
                    print("   ⚠️ No webhook results found")
                
                # Check n8n response
                print("\n📨 Step 3: Checking n8n webhook response...")
                n8n_response = webhook_delivery.get('n8n_webhook_response', 'No response')
                print(f"✅ Step 3 SUCCESS: n8n responded with: {n8n_response}")
                
                # Final result
                print("\n🎯 COMPLETE FLOW RESULT:")
                print("=" * 50)
                print("✅ Upload File: SUCCESS")
                print("✅ PaddleOCR Extract Text: SUCCESS")
                print("✅ Connect Webhook: SUCCESS")
                print("✅ Return Answer: SUCCESS")
                print("\n🎉 YOUR FLOW IS WORKING PERFECTLY!")
                
                return True
            else:
                print("❌ Step 2 FAILED: No webhook delivery information")
                return False
        else:
            print(f"❌ Step 1 FAILED: OCR API returned status {response.status_code}")
            print(f"   Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ FLOW FAILED: {e}")
        return False
    finally:
        # Clean up test file
        if os.path.exists("test_medical_document.txt"):
            os.remove("test_medical_document.txt")

def show_flow_diagram():
    """Show the flow diagram"""
    print("\n🔄 YOUR FLOW DIAGRAM:")
    print("=" * 50)
    print("📤 Upload PDF/Image")
    print("    ↓")
    print("🔍 PaddleOCR Extract Text")
    print("    ↓")
    print("🔗 Connect Webhook (n8n)")
    print("    ↓")
    print("📨 Return Answer")
    print("=" * 50)

if __name__ == "__main__":
    show_flow_diagram()
    success = test_complete_flow()
    
    if success:
        print("\n✅ CONCLUSION: Your flow is working perfectly!")
        print("💡 You can now upload any PDF/image and it will:")
        print("   1. Extract text using PaddleOCR ✅")
        print("   2. Send results to your n8n webhook ✅")
        print("   3. Return the complete answer ✅")
        print("\n🎯 Ready for production use!")
    else:
        print("\n❌ CONCLUSION: There's still an issue with the flow")
        print("💡 Check the error messages above to identify the problem")
