#!/usr/bin/env python3
"""
Quick test script to verify the setup works correctly
"""

import sys
import os

def test_imports():
    """Test if all required packages can be imported"""
    print("Testing package imports...")
    
    try:
        import cv2
        print(f"✓ OpenCV version: {cv2.__version__}")
    except ImportError as e:
        print(f"✗ OpenCV import failed: {e}")
        return False
    
    try:
        import numpy as np
        print(f"✓ NumPy version: {np.__version__}")
    except ImportError as e:
        print(f"✗ NumPy import failed: {e}")
        return False
    
    try:
        from ultralytics import YOLO
        print("✓ Ultralytics YOLO imported successfully")
    except ImportError as e:
        print(f"✗ Ultralytics import failed: {e}")
        return False
    
    try:
        import roboflow
        print("✓ Roboflow imported successfully")
    except ImportError as e:
        print(f"✗ Roboflow import failed: {e}")
        return False
    
    return True

def test_camera():
    """Test if camera is accessible"""
    print("\nTesting camera access...")
    
    try:
        import cv2
        
        # Test different camera indices
        for i in range(3):
            cap = cv2.VideoCapture(i)
            if cap.isOpened():
                ret, frame = cap.read()
                if ret:
                    print(f"✓ Camera found at index {i}")
                    print(f"  Frame shape: {frame.shape}")
                    cap.release()
                    return True
                cap.release()
        
        print("✗ No working camera found")
        return False
        
    except Exception as e:
        print(f"✗ Camera test failed: {e}")
        return False

def test_model_path():
    """Check if the model file exists"""
    print("\nChecking for model file...")
    
    model_path = "traffic-congestion-detection-9/train/weights/best.pt"
    
    if os.path.exists(model_path):
        print(f"✓ Model file found: {model_path}")
        return True
    else:
        print(f"✗ Model file not found: {model_path}")
        print("  Run 'python download_roboflow_model.py' first")
        return False

def test_basic_yolo():
    """Test basic YOLO functionality"""
    print("\nTesting basic YOLO functionality...")
    
    try:
        from ultralytics import YOLO
        
        # Try to load a basic YOLOv8 model
        model = YOLO('yolov8n.pt')  # This will download if not present
        print("✓ Basic YOLO model loaded successfully")
        
        # Test inference on a dummy image
        import numpy as np
        dummy_image = np.zeros((640, 640, 3), dtype=np.uint8)
        results = model(dummy_image)
        print("✓ YOLO inference test passed")
        
        return True
        
    except Exception as e:
        print(f"✗ YOLO test failed: {e}")
        return False

def main():
    print("=" * 60)
    print("Traffic Congestion Detection - System Test")
    print("=" * 60)
    
    all_tests_passed = True
    
    # Test 1: Package imports
    if not test_imports():
        all_tests_passed = False
    
    # Test 2: Camera access
    if not test_camera():
        all_tests_passed = False
        print("  Note: Camera test failure is OK if no camera is connected")
    
    # Test 3: Model file
    if not test_model_path():
        all_tests_passed = False
    
    # Test 4: Basic YOLO
    if not test_basic_yolo():
        all_tests_passed = False
    
    print("\n" + "=" * 60)
    if all_tests_passed:
        print("🎉 All tests passed! System is ready.")
        print("You can now run: python traffic_detector.py")
    else:
        print("❌ Some tests failed. Please check the issues above.")
        print("\nCommon solutions:")
        print("1. Install missing packages: pip install -r requirements.txt")
        print("2. Download model: python download_roboflow_model.py")
        print("3. Check camera connection")
    print("=" * 60)
    
    return all_tests_passed

if __name__ == "__main__":
    success = main()
    if not success:
        sys.exit(1)
