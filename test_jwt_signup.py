#!/usr/bin/env python3
"""
Test script for JWT-based signup flow
Tests the new signup process without temporary database storage
"""

import requests
import json
import time

# Configuration
BASE_URL = "http://localhost:5000"
TEST_EMAIL = "test_jwt@example.com"
TEST_USERNAME = "test_jwt_user"
TEST_MOBILE = "1234567890"
TEST_PASSWORD = "testpass123"

def test_jwt_signup_flow():
    """Test the complete JWT-based signup flow"""
    print("🧪 Testing JWT-based Signup Flow")
    print("=" * 50)
    
    # Step 1: Test signup endpoint
    print("\n1️⃣ Testing /signup endpoint...")
    signup_data = {
        "username": TEST_USERNAME,
        "email": TEST_EMAIL,
        "mobile": TEST_MOBILE,
        "password": TEST_PASSWORD,
        "role": "patient"
    }
    
    try:
        response = requests.post(f"{BASE_URL}/signup", json=signup_data)
        print(f"   Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ Signup successful!")
            print(f"   Email: {result.get('email')}")
            print(f"   Status: {result.get('status')}")
            print(f"   Message: {result.get('message')}")
            
            # Check if signup_token is present
            signup_token = result.get('signup_token')
            if signup_token:
                print(f"   ✅ Signup token received: {signup_token[:50]}...")
                return signup_token
            else:
                print("   ❌ No signup token received!")
                return None
        else:
            print(f"   ❌ Signup failed: {response.text}")
            return None
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return None

def test_verify_otp_with_jwt(signup_token, otp="123456"):
    """Test OTP verification with JWT token"""
    print(f"\n2️⃣ Testing /verify-otp with JWT token...")
    
    verify_data = {
        "email": TEST_EMAIL,
        "otp": otp,
        "role": "patient",
        "signup_token": signup_token
    }
    
    try:
        response = requests.post(f"{BASE_URL}/verify-otp", json=verify_data)
        print(f"   Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"   ✅ OTP verification successful!")
            print(f"   Patient ID: {result.get('patient_id')}")
            print(f"   Username: {result.get('username')}")
            print(f"   Email: {result.get('email')}")
            print(f"   Status: {result.get('status')}")
            print(f"   Token: {result.get('token', '')[:50]}...")
            print(f"   Message: {result.get('message')}")
            return True
        else:
            print(f"   ❌ OTP verification failed: {response.text}")
            return False
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

def test_invalid_otp(signup_token):
    """Test with invalid OTP"""
    print(f"\n3️⃣ Testing with invalid OTP...")
    
    verify_data = {
        "email": TEST_EMAIL,
        "otp": "999999",  # Invalid OTP
        "role": "patient",
        "signup_token": signup_token
    }
    
    try:
        response = requests.post(f"{BASE_URL}/verify-otp", json=verify_data)
        print(f"   Status Code: {response.status_code}")
        
        if response.status_code == 400:
            result = response.json()
            print(f"   ✅ Invalid OTP correctly rejected: {result.get('error')}")
            return True
        else:
            print(f"   ❌ Expected 400 error, got: {response.text}")
            return False
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

def test_expired_token():
    """Test with expired token (simulated)"""
    print(f"\n4️⃣ Testing with expired token...")
    
    # This would be a real expired token in production
    expired_token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VybmFtZSI6InRlc3QiLCJleHAiOjE2MDAwMDAwMDB9.invalid"
    
    verify_data = {
        "email": TEST_EMAIL,
        "otp": "123456",
        "role": "patient",
        "signup_token": expired_token
    }
    
    try:
        response = requests.post(f"{BASE_URL}/verify-otp", json=verify_data)
        print(f"   Status Code: {response.status_code}")
        
        if response.status_code == 400:
            result = response.json()
            print(f"   ✅ Expired token correctly rejected: {result.get('error')}")
            return True
        else:
            print(f"   ❌ Expected 400 error, got: {response.text}")
            return False
            
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

def main():
    """Run all tests"""
    print("🚀 Starting JWT-based Signup Flow Tests")
    print("=" * 60)
    
    # Test 1: Signup
    signup_token = test_jwt_signup_flow()
    if not signup_token:
        print("\n❌ Signup test failed. Stopping tests.")
        return
    
    # Test 2: Valid OTP verification
    success = test_verify_otp_with_jwt(signup_token)
    if not success:
        print("\n❌ OTP verification test failed.")
        return
    
    # Test 3: Invalid OTP
    test_invalid_otp(signup_token)
    
    # Test 4: Expired token
    test_expired_token()
    
    print("\n" + "=" * 60)
    print("✅ JWT-based signup flow tests completed!")
    print("\nKey Benefits:")
    print("• No temporary database storage")
    print("• Stateless JWT token approach")
    print("• Automatic token expiration")
    print("• Secure data transmission")

if __name__ == "__main__":
    main()

