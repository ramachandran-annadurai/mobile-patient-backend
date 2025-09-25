#!/usr/bin/env python3
"""
Test script to verify vital signs are being stored in the database
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app_simple import vital_signs_service, db
import json

def test_vital_signs_storage():
    print("🔍 Testing Vital Signs Database Storage...")
    
    # Test patient ID
    patient_id = "PAT1758709980FA11E5"
    
    # Test data
    test_data = {
        'type': 'heartRate',
        'value': 75.0,
        'notes': 'Test vital sign from script'
    }
    
    print(f"📊 Recording vital sign for patient: {patient_id}")
    print(f"📦 Test data: {test_data}")
    
    # Record vital sign
    result = vital_signs_service.record_vital_sign(patient_id, test_data)
    print(f"📥 Recording result: {json.dumps(result, indent=2, default=str)}")
    
    # Check if patient exists in database
    if db.patients_collection is not None:
        patient = db.patients_collection.find_one({"patient_id": patient_id})
        if patient:
            print(f"✅ Patient found in database: {patient['username']}")
            vital_signs = patient.get('vital_signs_logs', [])
            print(f"📊 Vital signs count: {len(vital_signs)}")
            if vital_signs:
                print(f"📋 Latest vital sign: {vital_signs[-1]}")
            else:
                print("❌ No vital signs found in patient record")
        else:
            print("❌ Patient not found in database")
    else:
        print("❌ Database collection is None")

if __name__ == "__main__":
    test_vital_signs_storage()
