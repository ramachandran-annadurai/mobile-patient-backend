#!/usr/bin/env python3
"""
Test to show exactly what PaddleOCR data is sent to the webhook
"""

import requests
import json
from datetime import datetime

def test_webhook_payload():
    """Test what data is sent to the webhook"""
    
    webhook_url = "https://n8n.srv795087.hstgr.cloud/webhook/vital"
    
    # Sample PaddleOCR result (this is what gets sent to webhook)
    sample_ocr_result = {
        "success": True,
        "filename": "sample_document.pdf",
        "text_count": 3,
        "processing_time": "2.5s",
        "results": [
            {
                "text": "Patient Name: John Doe",
                "confidence": 0.95,
                "bbox": [[100, 200], [300, 200], [300, 250], [100, 250]]
            },
            {
                "text": "Medication: Aspirin 100mg",
                "confidence": 0.88,
                "bbox": [[100, 300], [400, 300], [400, 350], [100, 350]]
            },
            {
                "text": "Dosage: Take twice daily",
                "confidence": 0.92,
                "bbox": [[100, 400], [350, 400], [350, 450], [100, 450]]
            }
        ]
    }
    
    # This is the EXACT payload that gets sent to your webhook
    webhook_payload = {
        "timestamp": datetime.now().isoformat(),
        "source": "paddleocr-microservice",
        "filename": "sample_document.pdf",
        "ocr_result": sample_ocr_result,  # Complete PaddleOCR results
        "full_text_content": "Text 1: Patient Name: John Doe (Confidence: 95.00%)\nText 2: Medication: Aspirin 100mg (Confidence: 88.00%)\nText 3: Dosage: Take twice daily (Confidence: 92.00%)",
        "metadata": {
            "text_count": 3,
            "config_name": "Default n8n Webhook"
        }
    }
    
    print("🔍 Testing Webhook with PaddleOCR Data")
    print("=" * 60)
    print(f"📡 Webhook URL: {webhook_url}")
    print(f"📦 Payload being sent:")
    print(json.dumps(webhook_payload, indent=2))
    print("-" * 60)
    
    try:
        response = requests.post(
            webhook_url,
            json=webhook_payload,
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        
        print(f"✅ Response Status: {response.status_code}")
        print(f"📝 Response Body: {response.text}")
        
        if response.status_code == 200:
            print("\n🎉 SUCCESS: PaddleOCR data was sent to webhook!")
            print("💡 Your n8n workflow should receive:")
            print("   - Complete OCR results with extracted text")
            print("   - Confidence scores for each text block")
            print("   - Bounding box coordinates")
            print("   - Full text content in readable format")
            print("   - Metadata (filename, text count, etc.)")
        else:
            print(f"\n⚠️ WARNING: Webhook responded with status {response.status_code}")
            
    except Exception as e:
        print(f"\n❌ ERROR: {e}")

if __name__ == "__main__":
    test_webhook_payload()
