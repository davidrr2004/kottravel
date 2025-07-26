#!/usr/bin/env python3
"""
Firebase Integration for Traffic Congestion Detection
Sends real-time traffic data to Firebase for IoT web and app integration
"""

import json
import time
import threading
from datetime import datetime
import requests

class FirebaseIntegration:
    def __init__(self, firebase_url, api_key=None):
        """
        Initialize Firebase connection
        
        Args:
            firebase_url: Your Firebase Realtime Database URL
            api_key: Optional Firebase API key for authentication
        """
        self.firebase_url = firebase_url.rstrip('/')
        self.api_key = api_key
        self.last_update = 0
        self.update_interval = 5  # Update every 5 seconds
        self.location_id = "camera_001"  # Unique identifier for this camera
        
    def format_traffic_data(self, congestion_status, vehicle_count, detections_in_roi, all_detections):
        """Format traffic data for Firebase"""
        timestamp = datetime.now().isoformat()
        
        # Convert congestion status to numeric level
        congestion_levels = {
            "No Traffic": 0,
            "Light Traffic": 1, 
            "Moderate Congestion": 2,
            "High Congestion": 3
        }
        
        # Count vehicles by type
        vehicle_types = {}
        for detection in all_detections:
            vehicle_type = detection['class_name']
            vehicle_types[vehicle_type] = vehicle_types.get(vehicle_type, 0) + 1
        
        data = {
            "timestamp": timestamp,
            "location_id": self.location_id,
            "congestion": {
                "status": congestion_status,
                "level": congestion_levels.get(congestion_status, 0),
                "vehicle_count_roi": vehicle_count,
                "total_detections": len(all_detections)
            },
            "vehicles": {
                "in_roi": vehicle_count,
                "total": len(all_detections),
                "types": vehicle_types
            },
            "metadata": {
                "camera_active": True,
                "last_detection": timestamp
            }
        }
        
        return data
    
    def send_to_firebase(self, data):
        """Send data to Firebase Realtime Database"""
        try:
            # Construct Firebase URL
            endpoint = f"{self.firebase_url}/traffic_data/{self.location_id}.json"
            
            if self.api_key:
                endpoint += f"?auth={self.api_key}"
            
            print(f"🔄 Sending to Firebase: {endpoint}")
            print(f"📊 Data: {data['congestion']['status']} - {data['vehicles']['in_roi']} vehicles")
            
            # Send PUT request to update the data
            response = requests.put(endpoint, json=data, timeout=10)
            
            if response.status_code == 200:
                print(f"✅ Data sent to Firebase successfully!")
                return True
            else:
                print(f"❌ Firebase error: {response.status_code}")
                print(f"Response: {response.text}")
                return False
                
        except requests.RequestException as e:
            print(f"❌ Network error sending to Firebase: {e}")
            return False
        except Exception as e:
            print(f"❌ Unexpected error: {e}")
            return False
    
    def send_historical_data(self, data):
        """Send data to historical collection with timestamp as key"""
        try:
            timestamp_key = str(int(time.time()))
            endpoint = f"{self.firebase_url}/traffic_history/{self.location_id}/{timestamp_key}.json"
            
            if self.api_key:
                endpoint += f"?auth={self.api_key}"
            
            response = requests.put(endpoint, json=data, timeout=10)
            return response.status_code == 200
            
        except Exception as e:
            print(f"Historical data error: {e}")
            return False
    
    def update_traffic_data(self, congestion_status, vehicle_count, detections_in_roi, all_detections):
        """Main method to update Firebase with traffic data"""
        current_time = time.time()
        
        # Only update if enough time has passed
        if current_time - self.last_update >= self.update_interval:
            print(f"🔄 Updating Firebase - Status: {congestion_status}, Vehicles: {vehicle_count}")
            
            data = self.format_traffic_data(congestion_status, vehicle_count, detections_in_roi, all_detections)
            
            # Send current data
            success = self.send_to_firebase(data)
            
            # Also send to historical data
            if success:
                threading.Thread(target=self.send_historical_data, args=(data,), daemon=True).start()
            
            self.last_update = current_time
            return success
        else:
            # Show that we're waiting
            time_until_next = self.update_interval - (current_time - self.last_update)
            if int(time_until_next) != int(time_until_next + 1):  # Only print once per second
                print(f"⏱️ Next Firebase update in {time_until_next:.1f}s")
        
        return True  # Don't update yet, but no error
    
    def send_alert(self, alert_type, message):
        """Send special alerts for high congestion or incidents"""
        try:
            alert_data = {
                "timestamp": datetime.now().isoformat(),
                "location_id": self.location_id,
                "alert_type": alert_type,
                "message": message,
                "severity": "high" if "High Congestion" in message else "medium"
            }
            
            endpoint = f"{self.firebase_url}/alerts/{self.location_id}.json"
            if self.api_key:
                endpoint += f"?auth={self.api_key}"
            
            response = requests.post(endpoint, json=alert_data, timeout=10)
            return response.status_code == 200
            
        except Exception as e:
            print(f"Alert error: {e}")
            return False
    
    def test_connection(self):
        """Test Firebase connection"""
        try:
            test_data = {
                "test": True,
                "timestamp": datetime.now().isoformat(),
                "location_id": self.location_id,
                "message": "Firebase connection test successful"
            }
            
            endpoint = f"{self.firebase_url}/test.json"
            if self.api_key:
                endpoint += f"?auth={self.api_key}"
            
            print(f"🔗 Testing Firebase connection to: {endpoint}")
            response = requests.put(endpoint, json=test_data, timeout=10)
            
            if response.status_code == 200:
                print("✅ Firebase connection successful!")
                
                # Also test the actual data endpoint
                data_endpoint = f"{self.firebase_url}/traffic_data/{self.location_id}.json"
                if self.api_key:
                    data_endpoint += f"?auth={self.api_key}"
                
                test_traffic_data = {
                    "timestamp": datetime.now().isoformat(),
                    "location_id": self.location_id,
                    "test_mode": True,
                    "congestion": {"status": "Test Mode", "level": 0}
                }
                
                test_response = requests.put(data_endpoint, json=test_traffic_data, timeout=10)
                if test_response.status_code == 200:
                    print("✅ Traffic data endpoint working!")
                    return True
                else:
                    print(f"⚠️ Traffic data endpoint failed: {test_response.status_code}")
                    return False
            else:
                print(f"❌ Firebase connection failed: {response.status_code}")
                print(f"Response: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Firebase connection test failed: {e}")
            return False
