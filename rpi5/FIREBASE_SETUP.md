# Firebase Setup Guide for Traffic Congestion Detection

## 🔥 Quick Firebase Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" 
3. Enter project name (e.g., "congesto-traffic" or "your-unique-name")
4. Disable Google Analytics (not needed)
5. Click "Create project"

### Step 2: Setup Realtime Database

1. In Firebase Console, go to "Realtime Database"
2. Click "Create Database"
3. Choose location (closest to your Pi)
4. Start in **test mode** (for now)
5. Copy your database URL (looks like: `https://congesto-traffic-default-rtdb.firebaseio.com/` or similar)

### Step 3: Configure Your System

Edit `traffic_detector.py` and replace:

```python
FIREBASE_URL = "https://your-project-id-default-rtdb.firebaseio.com/"  # Your actual URL
ENABLE_FIREBASE = True
```

### Step 4: Test Connection

```bash
# Run traffic detector
python traffic_detector.py

# Press 'f' to test Firebase connection
# You should see: "✓ Firebase connection test successful"
```

### Step 5: View Your Data

Go to Firebase Console > Realtime Database to see live traffic data!

## 📊 Data Structure

Your Firebase will have:

```
/traffic_data/camera_001/
├── timestamp
├── congestion/
│   ├── status ("No Traffic", "Light Traffic", etc.)
│   ├── level (0-3)
│   └── vehicle_count_roi
├── vehicles/
│   ├── in_roi
│   ├── total  
│   └── types/ (car: 5, truck: 2, etc.)
└── metadata/
    ├── camera_active
    └── last_detection

/traffic_history/camera_001/
├── 1721984200/ (timestamp)
├── 1721984205/
└── ...

/alerts/camera_001/
├── alert_type
├── message
├── severity
└── timestamp
```

## 🔐 Security (Optional)

For production, set database rules:

```json
{
  "rules": {
    "traffic_data": {
      ".read": true,
      ".write": true
    },
    "traffic_history": {
      ".read": true,
      ".write": true  
    },
    "alerts": {
      ".read": true,
      ".write": true
    }
  }
}
```

## 📱 Web/App Integration

Your web app or mobile app can read data from:

- **Current Status**: `/traffic_data/camera_001`
- **Historical Data**: `/traffic_history/camera_001`  
- **Alerts**: `/alerts/camera_001`

Example JavaScript (web):
```javascript
// Read current traffic status
const db = firebase.database();
db.ref('traffic_data/camera_001').on('value', (snapshot) => {
    const data = snapshot.val();
    console.log('Current traffic:', data.congestion.status);
    console.log('Vehicle count:', data.vehicles.in_roi);
});
```

## 🚀 Features Available

- ✅ Real-time traffic status
- ✅ Vehicle counting and classification  
- ✅ Historical data storage
- ✅ High congestion alerts
- ✅ Multiple camera support (change LOCATION_ID)
- ✅ Web/App ready JSON data

## 🛠 Customization

Edit `firebase_integration.py` to:
- Change update frequency
- Add more alert types
- Modify data structure
- Add location coordinates

Your IoT system is now Firebase-ready! 🎉
