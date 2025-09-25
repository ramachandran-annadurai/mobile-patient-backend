#!/usr/bin/env python3
"""
Debug webhook connection issues
"""

import requests
import json
from datetime import datetime

def debug_webhook_issue():
    """Debug why webhook is failing"""
    
    print("🔍 Debugging Webhook Connection Issues")
    print("=" * 60)
    
    # Step 1: Check webhook configurations
    print("📋 Step 1: Checking webhook configurations...")
    try:
        response = requests.get("http://localhost:8000/api/v1/webhook/configs")
        if response.status_code == 200:
            configs = response.json()
            print(f"✅ Found {len(configs)} webhook configurations")
            
            for config in configs:
                print(f"   - Name: {config.get('name', 'Unknown')}")
                print(f"     URL: {config.get('url', 'Unknown')}")
                print(f"     Enabled: {config.get('enabled', False)}")
                print(f"     Method: {config.get('method', 'Unknown')}")
                print()
        else:
            print(f"❌ Failed to get webhook configs: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Error getting webhook configs: {e}")
        return False
    
    # Step 2: Test webhook directly
    print("🔗 Step 2: Testing webhook directly...")
    webhook_url = "https://n8n.srv795087.hstgr.cloud/webhook/vital"
    
    test_payload = {
        "test": True,
        "timestamp": datetime.now().isoformat(),
        "source": "debug-test",
        "message": "Testing webhook connectivity"
    }
    
    try:
        response = requests.post(
            webhook_url,
            json=test_payload,
            headers={'Content-Type': 'application/json'},
            timeout=30
        )
        
        print(f"✅ Direct webhook test: Status {response.status_code}")
        print(f"   Response: {response.text}")
        
        if response.status_code == 200:
            print("✅ Webhook URL is accessible and working")
        else:
            print(f"⚠️ Webhook responded with status {response.status_code}")
            
    except Exception as e:
        print(f"❌ Direct webhook test failed: {e}")
        print("   This could be due to:")
        print("   - n8n server is down")
        print("   - Network connectivity issues")
        print("   - CORS policy blocking the request")
        print("   - Incorrect webhook URL")
    
    # Step 3: Test webhook through API
    print("\n🧪 Step 3: Testing webhook through API...")
    try:
        response = requests.post("http://localhost:8000/api/v1/webhook/test")
        if response.status_code == 200:
            result = response.json()
            print("✅ API webhook test successful")
            print(f"   Message: {result.get('message', 'No message')}")
            
            webhook_results = result.get('webhook_results', [])
            if webhook_results:
                print(f"   Webhook Results: {len(webhook_results)} webhook(s) tested")
                for i, webhook_result in enumerate(webhook_results):
                    print(f"     Webhook {i+1}:")
                    print(f"       Config: {webhook_result.get('config_name', 'Unknown')}")
                    print(f"       URL: {webhook_result.get('url', 'Unknown')}")
                    print(f"       Success: {webhook_result.get('success', False)}")
                    if not webhook_result.get('success', False):
                        print(f"       ❌ Error: {webhook_result.get('error', 'Unknown error')}")
            else:
                print("   ⚠️ No webhook results found")
        else:
            print(f"❌ API webhook test failed: {response.status_code}")
            print(f"   Response: {response.text}")
    except Exception as e:
        print(f"❌ API webhook test error: {e}")
    
    # Step 4: Check webhook service status
    print("\n📊 Step 4: Checking webhook service status...")
    try:
        response = requests.get("http://localhost:8000/api/v1/webhook/status")
        if response.status_code == 200:
            result = response.json()
            print("✅ Webhook service status retrieved")
            print(f"   Status: {json.dumps(result, indent=2)}")
        else:
            print(f"❌ Failed to get webhook status: {response.status_code}")
    except Exception as e:
        print(f"❌ Error getting webhook status: {e}")
    
    return True

def check_webhook_config_file():
    """Check the webhook configuration file"""
    print("\n📁 Step 5: Checking webhook configuration file...")
    
    try:
        with open("webhook_configs.json", "r") as f:
            config_data = json.load(f)
        
        print("✅ Webhook config file loaded successfully")
        
        for config_id, config in config_data.items():
            print(f"   Config ID: {config_id}")
            print(f"   Name: {config.get('name', 'Unknown')}")
            print(f"   URL: {config.get('url', 'Unknown')}")
            print(f"   Enabled: {config.get('enabled', False)}")
            print(f"   Method: {config.get('method', 'Unknown')}")
            print(f"   Headers: {config.get('headers', {})}")
            print()
            
    except Exception as e:
        print(f"❌ Error reading webhook config file: {e}")

if __name__ == "__main__":
    debug_webhook_issue()
    check_webhook_config_file()
    
    print("\n" + "=" * 60)
    print("🔧 TROUBLESHOOTING RECOMMENDATIONS:")
    print("=" * 60)
    print("1. Check if n8n server is running and accessible")
    print("2. Verify the webhook URL is correct")
    print("3. Check network connectivity")
    print("4. Ensure webhook configuration is enabled")
    print("5. Check CORS settings if testing from browser")
    print("6. Verify webhook service is properly initialized")
