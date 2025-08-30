#!/usr/bin/env python3
"""
Test different payload formats for N8N webhook to see which one triggers the workflow
"""

import requests
import json
import base64

N8N_WEBHOOK_URL = "https://n8n.srv795087.hstgr.cloud/webhook/food"

def create_test_audio():
    """Create test audio data"""
    return base64.b64encode("test_audio_data".encode()).decode()

def test_payload_format_1():
    """Test current format"""
    print("🧪 Testing Format 1: Current format")
    payload = {
        'audio_data': create_test_audio(),
        'action': 'transcribe_and_translate',
        'source_language': 'auto',
        'target_language': 'en',
        'audio_format': 'webm',
        'context': 'food_tracking',
    }
    return test_webhook(payload, "Format 1")

def test_payload_format_2():
    """Test simplified format"""
    print("🧪 Testing Format 2: Simplified")
    payload = {
        'audio': create_test_audio(),
        'language': 'auto'
    }
    return test_webhook(payload, "Format 2")

def test_payload_format_3():
    """Test direct audio format"""
    print("🧪 Testing Format 3: Direct audio")
    payload = {
        'audio_data': create_test_audio()
    }
    return test_webhook(payload, "Format 3")

def test_payload_format_4():
    """Test with different field names"""
    print("🧪 Testing Format 4: Different field names")
    payload = {
        'file': create_test_audio(),
        'type': 'audio',
        'action': 'transcribe'
    }
    return test_webhook(payload, "Format 4")

def test_payload_format_5():
    """Test minimal format"""
    print("🧪 Testing Format 5: Minimal")
    payload = {
        'data': create_test_audio()
    }
    return test_webhook(payload, "Format 5")

def test_webhook(payload, format_name):
    """Test webhook with given payload"""
    try:
        print(f"📤 Sending {format_name} to N8N webhook...")
        print(f"📦 Payload: {json.dumps({k: v if k not in ['audio_data', 'audio', 'file', 'data'] else f'[{len(v)} chars]' for k, v in payload.items()})}")
        
        response = requests.post(
            N8N_WEBHOOK_URL,
            json=payload,
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        
        print(f"📡 {format_name} Response status: {response.status_code}")
        print(f"📡 {format_name} Response: {response.text}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                print(f"✅ {format_name} JSON response: {data}")
                
                # Check if this looks like actual processing vs default response
                if data.get('output') == 'Hello!' or data.get('message') == 'Hello!':
                    print(f"⚠️ {format_name} seems to return default response")
                    return False
                else:
                    print(f"🎯 {format_name} might have triggered actual processing!")
                    return True
                    
            except json.JSONDecodeError:
                print(f"📄 {format_name} Non-JSON response: {response.text}")
                return False
        else:
            print(f"❌ {format_name} Failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ {format_name} Error: {e}")
        return False

def test_get_request():
    """Test GET request to see if webhook accepts it"""
    print("🧪 Testing GET request")
    try:
        response = requests.get(N8N_WEBHOOK_URL, timeout=10)
        print(f"📡 GET Response status: {response.status_code}")
        print(f"📡 GET Response: {response.text}")
    except Exception as e:
        print(f"❌ GET Error: {e}")

def main():
    print("🔍 N8N Webhook Format Testing")
    print("=" * 50)
    
    # Test different payload formats
    formats = [
        test_payload_format_1,
        test_payload_format_2,
        test_payload_format_3,
        test_payload_format_4,
        test_payload_format_5
    ]
    
    results = {}
    for i, test_func in enumerate(formats, 1):
        print(f"\n--- Test {i} ---")
        results[f"Format {i}"] = test_func()
        print()
    
    # Test GET request
    print("--- GET Test ---")
    test_get_request()
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 Test Results Summary:")
    for format_name, success in results.items():
        status = "🎯 TRIGGERED WORKFLOW" if success else "⚠️ DEFAULT RESPONSE"
        print(f"{format_name}: {status}")
    
    print(f"\n💡 Webhook URL: {N8N_WEBHOOK_URL}")
    print("💡 Check your N8N workflow to see which format it expects")
    print("💡 Look for webhook trigger node configuration in your N8N flow")

if __name__ == "__main__":
    main()
