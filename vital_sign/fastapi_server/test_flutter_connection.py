#!/usr/bin/env python3
"""
Test script to simulate Flutter app creating vital signs
"""

import requests
import json
from datetime import datetime

def test_flutter_vital_sign_creation():
    base_url = "http://localhost:8000"
    
    print("🧪 Testing Flutter Vital Sign Creation")
    print("=" * 50)
    
    # Test data that matches what Flutter sends
    test_vital_signs = [
        {
            "type": "temperature",
            "value": 38.0,
            "secondary_value": None,
            "timestamp": datetime.now().isoformat(),
            "notes": "Test from Flutter simulation",
            "is_anomaly": False,
            "confidence": 0.95
        },
        {
            "type": "bloodPressure", 
            "value": 120.0,
            "secondary_value": 80.0,
            "timestamp": datetime.now().isoformat(),
            "notes": "Blood pressure test",
            "is_anomaly": False,
            "confidence": 0.90
        }
    ]
    
    for i, vital_sign in enumerate(test_vital_signs, 1):
        print(f"\n📤 Test {i}: Creating {vital_sign['type']} vital sign")
        print(f"📊 Data: {json.dumps(vital_sign, indent=2)}")
        
        try:
            # Send POST request (same as Flutter would)
            response = requests.post(
                f"{base_url}/vital-signs",
                json=vital_sign,
                headers={"Content-Type": "application/json"},
                timeout=30
            )
            
            print(f"📥 Response Status: {response.status_code}")
            print(f"📥 Response Body: {response.text}")
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Success! Created vital sign with ID: {data.get('_id', 'Unknown')}")
            else:
                print(f"❌ Failed to create vital sign: {response.text}")
                
        except requests.exceptions.ConnectionError:
            print("❌ Connection Error: Cannot connect to backend server")
            break
        except requests.exceptions.Timeout:
            print("❌ Timeout Error: Request took too long")
        except Exception as e:
            print(f"❌ Error: {e}")
    
    # Verify data was stored
    print(f"\n🔍 Verifying data storage...")
    try:
        get_response = requests.get(f"{base_url}/vital-signs?limit=10")
        if get_response.status_code == 200:
            vital_signs = get_response.json()
            print(f"📊 Found {len(vital_signs)} vital signs in database")
            if vital_signs:
                print("📋 Recent vital signs:")
                for vs in vital_signs[:3]:  # Show first 3
                    print(f"   - {vs.get('type')}: {vs.get('value')} (ID: {vs.get('_id')})")
        else:
            print(f"❌ Failed to retrieve vital signs: {get_response.text}")
    except Exception as e:
        print(f"❌ Error retrieving data: {e}")

if __name__ == "__main__":
    test_flutter_vital_sign_creation()
