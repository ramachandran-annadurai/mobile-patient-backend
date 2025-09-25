#!/usr/bin/env python3
"""
Test database connection and vital signs storage
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def test_database_connection():
    print("🔍 Testing Database Connection...")
    
    try:
        from app_simple import db
        print("✅ Database object imported")
        
        # Check if database is connected
        print(f"📊 Is connected: {db.is_connected()}")
        print(f"📊 Client exists: {db.client is not None}")
        print(f"📊 Patients collection exists: {db.patients_collection is not None}")
        
        if not db.is_connected():
            print("🔄 Attempting to connect...")
            db.connect()
            print(f"📊 After connect - Is connected: {db.is_connected()}")
        
        # Test vital signs service
        from app_simple import vital_signs_service
        print("✅ Vital signs service imported")
        
        # Test recording a vital sign
        test_data = {
            'type': 'heartRate',
            'value': 75.0,
            'notes': 'Test from script'
        }
        
        result = vital_signs_service.record_vital_sign('PAT1758709980FA11E5', test_data)
        print(f"📊 Vital sign recording result: {result}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_database_connection()
