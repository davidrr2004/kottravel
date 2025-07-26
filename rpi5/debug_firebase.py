#!/usr/bin/env python3
"""
Firebase Debug Script - Test Firebase integration independently
"""

import requests
import json
from datetime import datetime

# Configuration - UPDATE THESE WITH YOUR FIREBASE DETAILS
FIREBASE_URL = "https://kottravel-2d580-default-rtdb.firebaseio.com/"  # Your correct Firebase URL
FIREBASE_API_KEY = None  # Optional

def test_firebase_write():
    """Test writing data to Firebase"""
    print("=" * 50)
    print("Firebase Write Test")
    print("=" * 50)
    
    # Test data
    test_data = {
        "timestamp": datetime.now().isoformat(),
        "location_id": "camera_001",
        "congestion": {
            "status": "Test Traffic",
            "level": 1,
            "vehicle_count_roi": 5
        },
        "vehicles": {
            "in_roi": 5,
            "total": 8,
            "types": {
                "car": 6,
                "truck": 2
            }
        },
        "metadata": {
            "camera_active": True,
            "test_mode": True
        }
    }
    
    # Construct endpoint
    endpoint = f"{FIREBASE_URL.rstrip('/')}/traffic_data/camera_001.json"
    if FIREBASE_API_KEY:
        endpoint += f"?auth={FIREBASE_API_KEY}"
    
    print(f"🔗 Endpoint: {endpoint}")
    print(f"📊 Data: {json.dumps(test_data, indent=2)}")
    
    try:
        response = requests.put(endpoint, json=test_data, timeout=10)
        
        print(f"\n📡 Response Status: {response.status_code}")
        print(f"📄 Response Text: {response.text}")
        
        if response.status_code == 200:
            print("✅ SUCCESS: Data written to Firebase!")
            print(f"🌐 View your data at: {FIREBASE_URL}")
            return True
        else:
            print("❌ FAILED: Could not write to Firebase")
            return False
            
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False

def test_firebase_read():
    """Test reading data from Firebase"""
    print("\n" + "=" * 50)
    print("Firebase Read Test")
    print("=" * 50)
    
    endpoint = f"{FIREBASE_URL.rstrip('/')}/traffic_data/camera_001.json"
    if FIREBASE_API_KEY:
        endpoint += f"?auth={FIREBASE_API_KEY}"
    
    try:
        response = requests.get(endpoint, timeout=10)
        
        print(f"📡 Response Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ SUCCESS: Data read from Firebase!")
            print(f"📊 Current Data: {json.dumps(data, indent=2)}")
            return True
        else:
            print(f"❌ FAILED: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False

def check_firebase_url():
    """Validate Firebase URL format"""
    print("=" * 50)
    print("Firebase URL Validation")
    print("=" * 50)
    
    if FIREBASE_URL == "https://your-project-id-default-rtdb.firebaseio.com/":
        print("❌ ERROR: You need to update FIREBASE_URL with your actual Firebase URL!")
        print("📝 Steps:")
        print("1. Go to Firebase Console")
        print("2. Select your project")
        print("3. Go to Realtime Database")
        print("4. Copy the URL (looks like: https://your-project-abc123-default-rtdb.firebaseio.com/)")
        print("5. Update FIREBASE_URL in this script AND in traffic_detector.py")
        return False
    
    if not FIREBASE_URL.startswith("https://") or not "firebaseio.com" in FIREBASE_URL:
        print(f"⚠️ WARNING: Firebase URL might be incorrect: {FIREBASE_URL}")
        print("Expected format: https://your-project-id-default-rtdb.firebaseio.com/")
    
    print(f"🔗 Firebase URL: {FIREBASE_URL}")
    print("✅ URL format looks correct")
    return True

def main():
    print("🔥 Firebase Integration Debug Tool")
    print("=" * 50)
    
    # Step 1: Check URL
    if not check_firebase_url():
        return False
    
    # Step 2: Test write
    write_success = test_firebase_write()
    
    # Step 3: Test read  
    read_success = test_firebase_read()
    
    print("\n" + "=" * 50)
    print("🔥 Firebase Debug Summary")
    print("=" * 50)
    print(f"URL Valid: {'✅' if FIREBASE_URL != 'https://your-project-id-default-rtdb.firebaseio.com/' else '❌'}")
    print(f"Write Test: {'✅' if write_success else '❌'}")
    print(f"Read Test: {'✅' if read_success else '❌'}")
    
    if write_success and read_success:
        print("\n🎉 Firebase is working correctly!")
        print("Your traffic detection system should now update Firebase.")
    else:
        print("\n❌ Firebase has issues. Please:")
        print("1. Check your Firebase URL")
        print("2. Verify database is in test mode")
        print("3. Check internet connection")
    
    return write_success and read_success

if __name__ == "__main__":
    success = main()
    input("\nPress Enter to exit...")
