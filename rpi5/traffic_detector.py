#!/usr/bin/env python3
"""
Traffic Congestion Detection using Pre-trained YOLOv8 Model from Roboflow
Optimized for Raspberry Pi 5 with Pi Camera

This script uses a pre-trained model from Roboflow Universe:
"Traffic Congestion Detection Object Detection Dataset (v9) by SXC"
"""

import cv2
import numpy as np
from ultralytics import YOLO
import time
import os
import sys
from firebase_integration import FirebaseIntegration

# --- Configuration ---
# Path to your downloaded model from Roboflow
MODEL_PATH = 'traffic-congestion-detection-9/train/weights/best.pt'  # Roboflow download path
CAMERA_INDEX = 0  # 0 for Pi Camera, or USB camera index
FRAME_WIDTH = 640
FRAME_HEIGHT = 480
CONFIDENCE_THRESHOLD = 0.5

# Region of Interest (ROI) - adjust based on your camera view
# Format: [x1, y1, x2, y2] where (x1,y1) is top-left, (x2,y2) is bottom-right
ROI = [100, 200, 540, 400]  # Adjust these values for your specific view

# Congestion thresholds (adjusted for better detection)
LOW_CONGESTION_THRESHOLD = 2  # 2+ vehicles = light traffic
MODERATE_CONGESTION_THRESHOLD = 4  # 4+ vehicles = moderate congestion  
HIGH_CONGESTION_THRESHOLD = 6  # 6+ vehicles = high congestion

# Firebase Configuration
FIREBASE_URL = "https://kottravel-2d580-default-rtdb.firebaseio.com/"  # Fixed: Proper database URL
FIREBASE_API_KEY = None  # Optional: Replace with your Firebase API key
ENABLE_FIREBASE = True  # Set to False to disable Firebase integration

class TrafficDetector:
    def __init__(self):
        self.model = None
        self.cap = None
        self.class_names = {}
        self.vehicle_classes = []
        self.firebase = None
        self.last_congestion_status = None
        
        # Initialize Firebase if enabled
        if ENABLE_FIREBASE:
            try:
                self.firebase = FirebaseIntegration(FIREBASE_URL, FIREBASE_API_KEY)
                print("Firebase integration initialized")
            except Exception as e:
                print(f"Firebase initialization failed: {e}")
                self.firebase = None
        
    def setup_model(self):
        """Load the pre-trained model and identify classes"""
        try:
            print("Loading pre-trained model from Roboflow...")
            self.model = YOLO(MODEL_PATH)
            self.class_names = self.model.names
            print(f"Model loaded successfully!")
            print(f"Available classes: {self.class_names}")
            
            # Identify vehicle-related classes
            vehicle_keywords = ['car', 'truck', 'bus', 'motorcycle', 'vehicle', 'congested', 'not_congested']
            for class_id, class_name in self.class_names.items():
                if any(keyword in class_name.lower() for keyword in vehicle_keywords):
                    self.vehicle_classes.append(class_id)
                    
            print(f"Vehicle/Traffic classes identified: {[self.class_names[i] for i in self.vehicle_classes]}")
            
            if not self.vehicle_classes:
                print("Warning: No vehicle classes found. Using all classes.")
                self.vehicle_classes = list(self.class_names.keys())
                
            return True
            
        except Exception as e:
            print(f"Error loading model: {e}")
            print("Please ensure the model file exists at the specified path.")
            return False
    
    def setup_camera(self):
        """Initialize camera"""
        try:
            print("Initializing camera...")
            self.cap = cv2.VideoCapture(CAMERA_INDEX)
            
            if not self.cap.isOpened():
                print(f"Error: Could not open camera at index {CAMERA_INDEX}")
                return False
                
            # Set camera properties
            self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, FRAME_WIDTH)
            self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, FRAME_HEIGHT)
            self.cap.set(cv2.CAP_PROP_FPS, 30)
            
            print("Camera initialized successfully!")
            return True
            
        except Exception as e:
            print(f"Error setting up camera: {e}")
            return False
    
    def analyze_congestion(self, detections_in_roi):
        """Analyze congestion level based on detections"""
        if not detections_in_roi:
            return "No Traffic", (0, 255, 0)  # Green
        
        # Check if model directly detects congestion states
        congestion_detected = False
        for detection in detections_in_roi:
            class_name = self.class_names[detection['class_id']].lower()
            if 'congested' in class_name or 'congestion' in class_name:
                congestion_detected = True
                break
        
        if congestion_detected:
            return "High Congestion", (0, 0, 255)  # Red
        
        # Vehicle counting with improved thresholds
        vehicle_count = len(detections_in_roi)
        
        if vehicle_count >= HIGH_CONGESTION_THRESHOLD:
            return "High Congestion", (0, 0, 255)  # Red
        elif vehicle_count >= MODERATE_CONGESTION_THRESHOLD:
            return "Moderate Congestion", (0, 165, 255)  # Orange
        elif vehicle_count >= LOW_CONGESTION_THRESHOLD:
            return "Light Traffic", (0, 255, 255)  # Yellow
        else:
            return "No Traffic", (0, 255, 0)  # Green
    
    def process_frame(self, frame):
        """Process a single frame for traffic detection"""
        # Run inference
        results = self.model(frame, conf=CONFIDENCE_THRESHOLD)
        
        detections_in_roi = []
        all_detections = []
        
        # Process detections
        for result in results:
            boxes = result.boxes
            if boxes is not None:
                for box in boxes:
                    # Extract box coordinates and info
                    x1, y1, x2, y2 = map(int, box.xyxy[0])
                    class_id = int(box.cls[0])
                    confidence = float(box.conf[0])
                    class_name = self.class_names[class_id]
                    
                    detection = {
                        'bbox': (x1, y1, x2, y2),
                        'class_id': class_id,
                        'class_name': class_name,
                        'confidence': confidence
                    }
                    all_detections.append(detection)
                    
                    # Check if detection is in ROI and is a relevant class
                    if (class_id in self.vehicle_classes and 
                        x1 >= ROI[0] and y1 >= ROI[1] and 
                        x2 <= ROI[2] and y2 <= ROI[3]):
                        detections_in_roi.append(detection)
        
        return all_detections, detections_in_roi
    
    def draw_annotations(self, frame, all_detections, detections_in_roi, congestion_status, status_color):
        """Draw bounding boxes and annotations on the frame"""
        # Draw ROI
        cv2.rectangle(frame, (ROI[0], ROI[1]), (ROI[2], ROI[3]), (255, 255, 255), 2)
        cv2.putText(frame, "ROI", (ROI[0], ROI[1] - 10), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        
        # Draw all detections
        for detection in all_detections:
            x1, y1, x2, y2 = detection['bbox']
            class_name = detection['class_name']
            confidence = detection['confidence']
            
            # Color coding: Green for detections outside ROI, Red for inside ROI
            color = (0, 255, 0) if detection not in detections_in_roi else (0, 0, 255)
            
            # Draw bounding box
            cv2.rectangle(frame, (x1, y1), (x2, y2), color, 2)
            
            # Draw label
            label = f"{class_name}: {confidence:.2f}"
            label_size = cv2.getTextSize(label, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 2)[0]
            cv2.rectangle(frame, (x1, y1 - label_size[1] - 10), 
                         (x1 + label_size[0], y1), color, -1)
            cv2.putText(frame, label, (x1, y1 - 5), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 2)
        
        # Draw congestion status
        cv2.putText(frame, f"Status: {congestion_status}", (10, 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, status_color, 2)
        cv2.putText(frame, f"Vehicles in ROI: {len(detections_in_roi)}", (10, 60), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        
        # Draw timestamp
        timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
        cv2.putText(frame, timestamp, (10, frame.shape[0] - 10), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        
        return frame
    
    def run(self):
        """Main detection loop"""
        if not self.setup_model():
            return False
            
        if not self.setup_camera():
            return False
        
        print("\nTraffic Detection Started!")
        print("Press 'q' to quit")
        print("Press 's' to save current frame")
        print("Press 'r' to reset ROI (follow prompts)")
        print("Press 'f' to test Firebase connection")
        print("Press 'u' to force Firebase update now")
        
        # Test Firebase connection if enabled
        if self.firebase:
            if self.firebase.test_connection():
                print("✓ Firebase connected and ready")
            else:
                print("⚠ Firebase connection failed - continuing without Firebase")
                self.firebase = None
        
        print("-" * 50)
        
        frame_count = 0
        fps_counter = time.time()
        
        try:
            while True:
                ret, frame = self.cap.read()
                if not ret:
                    print("Error: Could not read frame from camera")
                    break
                
                # Process frame
                all_detections, detections_in_roi = self.process_frame(frame)
                
                # Analyze congestion
                congestion_status, status_color = self.analyze_congestion(detections_in_roi)
                
                # Send data to Firebase
                if self.firebase:
                    try:
                        self.firebase.update_traffic_data(
                            congestion_status, 
                            len(detections_in_roi), 
                            detections_in_roi, 
                            all_detections
                        )
                        
                        # Send alert for high congestion (only once per status change)
                        if (congestion_status == "High Congestion" and 
                            self.last_congestion_status != "High Congestion"):
                            self.firebase.send_alert(
                                "high_congestion", 
                                f"High traffic congestion detected: {len(detections_in_roi)} vehicles in ROI"
                            )
                    except Exception as e:
                        print(f"Firebase update error: {e}")
                
                self.last_congestion_status = congestion_status
                
                # Draw annotations
                annotated_frame = self.draw_annotations(
                    frame, all_detections, detections_in_roi, congestion_status, status_color
                )
                
                # Calculate and display FPS
                frame_count += 1
                if frame_count % 30 == 0:
                    fps = 30 / (time.time() - fps_counter)
                    fps_counter = time.time()
                    print(f"FPS: {fps:.1f} | Detections: {len(all_detections)} | ROI: {len(detections_in_roi)} | Status: {congestion_status}")
                
                # Display frame
                cv2.imshow('Traffic Congestion Detection', annotated_frame)
                
                # Handle key presses
                key = cv2.waitKey(1) & 0xFF
                if key == ord('q'):
                    break
                elif key == ord('s'):
                    filename = f"traffic_snapshot_{int(time.time())}.jpg"
                    cv2.imwrite(filename, annotated_frame)
                    print(f"Frame saved as {filename}")
                elif key == ord('f'):
                    if self.firebase:
                        if self.firebase.test_connection():
                            print("✓ Firebase connection test successful")
                        else:
                            print("✗ Firebase connection test failed")
                    else:
                        print("Firebase not enabled")
                elif key == ord('u'):
                    if self.firebase:
                        # Force immediate Firebase update
                        print("🔄 Forcing Firebase update...")
                        self.firebase.last_update = 0  # Reset timer
                        success = self.firebase.update_traffic_data(
                            congestion_status, 
                            len(detections_in_roi), 
                            detections_in_roi, 
                            all_detections
                        )
                        if success:
                            print("✅ Manual Firebase update completed")
                        else:
                            print("❌ Manual Firebase update failed")
                    else:
                        print("Firebase not enabled")
                elif key == ord('r'):
                    print("Click and drag to select new ROI, then press ENTER or SPACE")
                    roi = cv2.selectROI("Select ROI", frame, False)
                    if roi[2] > 0 and roi[3] > 0:  # Valid ROI selected
                        global ROI
                        ROI = [roi[0], roi[1], roi[0] + roi[2], roi[1] + roi[3]]
                        print(f"New ROI set: {ROI}")
                    cv2.destroyWindow("Select ROI")
                    
        except KeyboardInterrupt:
            print("\nDetection stopped by user")
        except Exception as e:
            print(f"Error during detection: {e}")
        finally:
            self.cleanup()
    
    def cleanup(self):
        """Clean up resources"""
        if self.cap:
            self.cap.release()
        cv2.destroyAllWindows()
        print("Resources cleaned up. Goodbye!")

def main():
    # Check if model file exists
    if not os.path.exists(MODEL_PATH):
        print(f"Error: Model file not found at {MODEL_PATH}")
        print("Please download the model using the Roboflow setup script first.")
        print("Run: python download_roboflow_model.py")
        return False
    
    detector = TrafficDetector()
    detector.run()
    return True

if __name__ == "__main__":
    main()
