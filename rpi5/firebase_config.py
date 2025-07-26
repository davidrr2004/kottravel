# Firebase Configuration for Traffic Congestion Detection
# Replace these values with your actual Firebase project details

# Your Firebase Realtime Database URL
# Get this from Firebase Console > Project Settings > General
FIREBASE_URL = "https://your-project-id-default-rtdb.firebaseio.com/"

# Optional: Firebase API Key for authentication
# Get this from Firebase Console > Project Settings > Web API Key
FIREBASE_API_KEY = None  # Or "your-api-key-here"

# Camera/Location Settings
LOCATION_ID = "camera_001"  # Unique identifier for this camera location
LOCATION_NAME = "Main Street Traffic"  # Human-readable location name
LOCATION_COORDINATES = {
    "latitude": 0.0,    # Replace with actual coordinates
    "longitude": 0.0
}

# Data Update Settings
UPDATE_INTERVAL = 5  # Send data to Firebase every 5 seconds
ENABLE_HISTORICAL_DATA = True  # Save historical traffic data
ENABLE_ALERTS = True  # Send alerts for high congestion

# Example Firebase Database Structure:
"""
{
  "traffic_data": {
    "camera_001": {
      "timestamp": "2025-07-26T10:30:00.000Z",
      "location_id": "camera_001",
      "congestion": {
        "status": "High Congestion",
        "level": 3,
        "vehicle_count_roi": 8,
        "total_detections": 12
      },
      "vehicles": {
        "in_roi": 8,
        "total": 12,
        "types": {
          "car": 10,
          "truck": 2
        }
      },
      "metadata": {
        "camera_active": true,
        "last_detection": "2025-07-26T10:30:00.000Z"
      }
    }
  },
  "traffic_history": {
    "camera_001": {
      "1721984200": { ... },  // Timestamp as key
      "1721984205": { ... }
    }
  },
  "alerts": {
    "camera_001": [
      {
        "timestamp": "2025-07-26T10:30:00.000Z",
        "alert_type": "high_congestion",
        "message": "High traffic congestion detected: 8 vehicles in ROI",
        "severity": "high"
      }
    ]
  }
}
"""
