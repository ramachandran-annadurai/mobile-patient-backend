#!/usr/bin/env python3
"""
Test script to verify CORS fix for N8N webhook integration
"""

import requests
import json
import base64

def test_backend_n8n_proxy():
    """Test the backend N8N proxy endpoint"""
    print("🧪 Testing backend N8N proxy...")
    
    # Create test audio data
    test_audio = "test_audio_data"
    test_audio_base64 = base64.b64encode(test_audio.encode()).decode()
    
    # Test payload for backend
    payload = {
        'audio': test_audio_base64,
        'language': 'auto',
        'method': 'n8n_webhook',
        'use_n8n': True
    }
    
    try:
        print("📡 Sending request to backend N8N proxy...")
        response = requests.post(
            'http://127.0.0.1:5000/nutrition/transcribe',
            json=payload,
            timeout=30
        )
        
        print(f"📡 Response status: {response.status_code}")
        print(f"📡 Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            if data.get('success'):
                method = data.get('method')
                transcription = data.get('transcription')
                print(f"✅ Success! Method: {method}")
                print(f"🎯 Transcription: {transcription}")
                return True
            else:
                print(f"❌ Backend returned error: {data.get('message')}")
        else:
            print(f"❌ HTTP error: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        
    return False

def test_direct_n8n_webhook():
    """Test direct N8N webhook call from Python (should work)"""
    print("\n🧪 Testing direct N8N webhook call...")
    
    payload = {
        'audio_data': base64.b64encode("test_audio".encode()).decode(),
        'action': 'transcribe_and_translate',
        'source_language': 'auto',
        'target_language': 'en',
        'audio_format': 'webm',
        'context': 'food_tracking',
    }
    
    try:
        print("📡 Calling N8N webhook directly...")
        response = requests.post(
            'https://n8n.srv795087.hstgr.cloud/webhook/food',
            json=payload,
            timeout=30
        )
        
        print(f"📡 Direct N8N response status: {response.status_code}")
        print(f"📡 Direct N8N response: {response.text}")
        
        if response.status_code == 200:
            print("✅ Direct N8N webhook call successful!")
            return True
        else:
            print(f"❌ Direct N8N call failed: {response.status_code}")
            
    except Exception as e:
        print(f"❌ Direct N8N error: {e}")
        
    return False

def main():
    print("🔧 CORS Fix Verification Test")
    print("=" * 40)
    
    # Test 1: Direct N8N webhook (should work from Python)
    direct_ok = test_direct_n8n_webhook()
    
    # Test 2: Backend proxy (should also work)
    proxy_ok = test_backend_n8n_proxy()
    
    print("\n" + "=" * 40)
    print("📊 Test Results:")
    print(f"🌐 Direct N8N: {'✅ PASS' if direct_ok else '❌ FAIL'}")
    print(f"🔧 Backend Proxy: {'✅ PASS' if proxy_ok else '❌ FAIL'}")
    
    if proxy_ok:
        print("\n🎉 CORS fix successful! Flutter should now work via backend proxy.")
    else:
        print("\n⚠️ Backend proxy not working. Check backend logs for details.")

if __name__ == "__main__":
    main()
