#!/usr/bin/env python3
"""
Test script for N8N food webhook integration
Tests audio transcription + translation flow
"""

import requests
import json
import base64
import time

# N8N webhook URL
N8N_WEBHOOK_URL = "https://n8n.srv795087.hstgr.cloud/webhook/food"

def test_n8n_webhook_connectivity():
    """Test if N8N webhook is accessible"""
    print("🔍 Testing N8N webhook connectivity...")
    try:
        # Simple connectivity test
        response = requests.get(N8N_WEBHOOK_URL.replace('/webhook/food', '/webhook/'), timeout=10)
        print(f"✅ N8N server reachable (status: {response.status_code})")
        return True
    except Exception as e:
        print(f"❌ N8N server not reachable: {e}")
        return False

def create_test_audio_data():
    """Create a simple test audio data (mock base64)"""
    # This is just a mock - in real usage, this would be actual base64 encoded audio
    test_audio_content = "mock_audio_content_for_testing"
    test_audio_base64 = base64.b64encode(test_audio_content.encode()).decode()
    return test_audio_base64

def test_n8n_food_webhook():
    """Test the N8N food webhook with sample data"""
    print("🎤 Testing N8N food webhook transcription...")
    
    # Create test payload
    test_payload = {
        'audio_data': create_test_audio_data(),
        'action': 'transcribe_and_translate',
        'source_language': 'auto',
        'target_language': 'en',
        'audio_format': 'webm',
        'context': 'food_tracking',
    }
    
    try:
        print(f"📡 Sending request to: {N8N_WEBHOOK_URL}")
        print(f"📝 Payload: {json.dumps(test_payload, indent=2)}")
        
        response = requests.post(
            N8N_WEBHOOK_URL,
            json=test_payload,
            headers={'Content-Type': 'application/json'},
            timeout=60
        )
        
        print(f"📡 Response status: {response.status_code}")
        print(f"📡 Response headers: {dict(response.headers)}")
        print(f"📡 Response body: {response.text}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                print("✅ N8N webhook responded successfully!")
                print(f"📋 Response data: {json.dumps(data, indent=2)}")
                
                # Check for expected response fields
                if data.get('success') or data.get('status') == 'success':
                    transcription = data.get('transcription') or data.get('translated_text') or data.get('text')
                    if transcription:
                        print(f"🎯 Transcription result: {transcription}")
                        return True
                    else:
                        print("⚠️ No transcription found in response")
                else:
                    print(f"⚠️ Webhook returned unsuccessful status: {data}")
                
            except json.JSONDecodeError as e:
                print(f"❌ Invalid JSON response: {e}")
                return False
        else:
            print(f"❌ HTTP error: {response.status_code}")
            return False
            
    except requests.exceptions.Timeout:
        print("❌ Request timed out (60 seconds)")
        return False
    except Exception as e:
        print(f"❌ Error testing N8N webhook: {e}")
        return False

def test_backend_integration():
    """Test the backend integration with N8N webhook"""
    print("🔧 Testing backend integration...")
    
    # Test local backend endpoint that now uses N8N webhook
    backend_url = "http://127.0.0.1:5000/nutrition/transcribe"
    
    test_payload = {
        'audio': create_test_audio_data(),
        'language': 'auto',
        'method': 'whisper',
    }
    
    try:
        print(f"📡 Testing backend endpoint: {backend_url}")
        response = requests.post(
            backend_url,
            json=test_payload,
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        
        print(f"📡 Backend response status: {response.status_code}")
        print(f"📡 Backend response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                method = data.get('method', 'unknown')
                transcription = data.get('transcription')
                print(f"✅ Backend integration successful!")
                print(f"🔧 Method used: {method}")
                print(f"🎯 Transcription: {transcription}")
                return True
            else:
                print(f"⚠️ Backend returned error: {data.get('message')}")
        else:
            print(f"❌ Backend HTTP error: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Backend test failed: {e}")
        return False

def main():
    """Main test function"""
    print("🧪 N8N Food Webhook Integration Test")
    print("=" * 50)
    
    # Test 1: Connectivity
    connectivity_ok = test_n8n_webhook_connectivity()
    
    # Test 2: N8N Webhook functionality
    webhook_ok = test_n8n_food_webhook()
    
    # Test 3: Backend integration
    backend_ok = test_backend_integration()
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    print(f"🌐 N8N Connectivity: {'✅ PASS' if connectivity_ok else '❌ FAIL'}")
    print(f"🎤 N8N Webhook: {'✅ PASS' if webhook_ok else '❌ FAIL'}")
    print(f"🔧 Backend Integration: {'✅ PASS' if backend_ok else '❌ FAIL'}")
    
    if all([connectivity_ok, webhook_ok, backend_ok]):
        print("\n🎉 All tests passed! N8N integration is working correctly.")
    else:
        print("\n⚠️ Some tests failed. Check the logs above for details.")
        print("\n💡 Troubleshooting tips:")
        print("   - Ensure N8N webhook is properly configured")
        print("   - Check N8N workflow is active and published")
        print("   - Verify backend server is running on port 5000")
        print("   - Check network connectivity to N8N server")

if __name__ == "__main__":
    main()
