#!/usr/bin/env python3
"""
Test script to verify vital sign creation and storage in patient collection
"""

import requests
import json
from datetime import datetime

def test_vital_sign_creation():
    base_url = "http://localhost:8000"
    
    print("🧪 Testing Vital Sign Creation")
    print("=" * 50)
    
    # Test data
    test_vital_sign = {
        "type": "temperature",
        "value": 37.5,
        "secondary_value": None,
        "timestamp": datetime.now().isoformat(),
        "notes": "Test vital sign from script",
        "is_anomaly": False,
        "confidence": 0.95
    }
    
    print(f"📤 Sending POST request to {base_url}/vital-signs")
    print(f"📊 Data: {json.dumps(test_vital_sign, indent=2)}")
    
    try:
        # Send POST request
        response = requests.post(
            f"{base_url}/vital-signs",
            json=test_vital_sign,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        print(f"📥 Response Status: {response.status_code}")
        print(f"📥 Response Headers: {dict(response.headers)}")
        print(f"📥 Response Body: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Success! Created vital sign with ID: {data.get('_id', 'Unknown')}")
            
            # Verify the data was stored by getting it back
            print("\n🔍 Verifying data storage...")
            get_response = requests.get(f"{base_url}/vital-signs?limit=10")
            if get_response.status_code == 200:
                vital_signs = get_response.json()
                print(f"📊 Found {len(vital_signs)} vital signs in database")
                if vital_signs:
                    latest = vital_signs[0]
                    print(f"📋 Latest vital sign: {json.dumps(latest, indent=2, default=str)}")
            else:
                print(f"❌ Failed to retrieve vital signs: {get_response.text}")
        else:
            print(f"❌ Failed to create vital sign: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Connection Error: Cannot connect to backend server")
        print("💡 Make sure the FastAPI server is running on http://localhost:8000")
    except requests.exceptions.Timeout:
        print("❌ Timeout Error: Request took too long")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    test_vital_sign_creation()
