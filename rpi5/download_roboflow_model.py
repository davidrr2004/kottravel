#!/usr/bin/env python3
"""
Download and setup the pre-trained traffic congestion model from Roboflow
Run this script first to download the model before running traffic_detector.py
"""

import os
import sys

def install_roboflow():
    """Install roboflow package if not already installed"""
    try:
        import roboflow
        print("Roboflow already installed")
        return True
    except ImportError:
        print("Installing roboflow...")
        os.system("pip install roboflow")
        try:
            import roboflow
            print("Roboflow installed successfully")
            return True
        except ImportError:
            print("Failed to install roboflow")
            return False

def download_model_direct():
    """Download the model using direct curl command"""
    try:
        print("Downloading model using direct URL...")
        
        # Download using curl (works on Linux/Pi)
        download_cmd = 'curl -L "https://universe.roboflow.com/ds/gRRYEMu1HL?key=Poykx80Izj" > roboflow.zip'
        print(f"Running: {download_cmd}")
        
        result = os.system(download_cmd)
        if result != 0:
            print("curl command failed, trying with Python requests...")
            return download_model_requests()
        
        # Unzip the file
        print("Extracting downloaded files...")
        unzip_result = os.system("unzip roboflow.zip")
        if unzip_result != 0:
            print("Unzip failed, trying Python zipfile...")
            return extract_with_python()
        
        # Clean up zip file
        os.system("rm roboflow.zip")
        
        print("Model downloaded and extracted successfully!")
        return verify_model_files()
        
    except Exception as e:
        print(f"Error in direct download: {e}")
        return download_model_api()

def download_model_requests():
    """Download using Python requests as fallback"""
    try:
        import requests
        
        url = "https://universe.roboflow.com/ds/gRRYEMu1HL?key=Poykx80Izj"
        print("Downloading with Python requests...")
        
        response = requests.get(url, stream=True)
        response.raise_for_status()
        
        with open("roboflow.zip", "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        return extract_with_python()
        
    except Exception as e:
        print(f"Requests download failed: {e}")
        return download_model_api()

def extract_with_python():
    """Extract zip file using Python"""
    try:
        import zipfile
        
        print("Extracting with Python zipfile...")
        with zipfile.ZipFile("roboflow.zip", 'r') as zip_ref:
            zip_ref.extractall(".")
        
        # Clean up
        os.remove("roboflow.zip")
        
        return verify_model_files()
        
    except Exception as e:
        print(f"Python extraction failed: {e}")
        return False

def download_model_api():
    """Download the pre-trained model using Roboflow API (original method)"""
    try:
        from roboflow import Roboflow
        
        print("Trying Roboflow API method...")
        # Use the API key provided
        rf = Roboflow(api_key="sie52IJKydchKLLK92Uv")
        
        print("Accessing SXC workspace...")
        project = rf.workspace("sxc").project("traffic-congestion-detection")
        
        print("Getting version 9 of the dataset...")
        version = project.version(9)
        
        print("Downloading YOLOv8 model...")
        dataset = version.download("yolov8")
        
        print("Model downloaded successfully via API!")
        return verify_model_files()
        
    except Exception as e:
        print(f"Error downloading model via API: {e}")
        print("Please check your internet connection and API key")
        return False

def verify_model_files():
    """Verify that model files were downloaded correctly"""
    print("Verifying downloaded files...")
    
    # Look for common model paths
    possible_paths = [
        "traffic-congestion-detection-9/train/weights/best.pt",
        "train/weights/best.pt",
        "weights/best.pt",
        "best.pt"
    ]
    
    found_model = None
    for path in possible_paths:
        if os.path.exists(path):
            found_model = path
            print(f"✓ Model weights found at: {path}")
            break
    
    if not found_model:
        print("Looking for any .pt files...")
        # Search for any .pt files in current directory and subdirectories
        for root, dirs, files in os.walk("."):
            for file in files:
                if file.endswith('.pt'):
                    full_path = os.path.join(root, file)
                    print(f"Found model file: {full_path}")
                    found_model = full_path
    
    if found_model:
        print(f"✓ Model ready at: {os.path.abspath(found_model)}")
        
        # Update the traffic_detector.py with correct path if needed
        update_model_path(found_model)
        
        return True
    else:
        print("✗ No model files found")
        return False

def update_model_path(model_path):
    """Update the MODEL_PATH in traffic_detector.py if needed"""
    try:
        with open("traffic_detector.py", "r") as f:
            content = f.read()
        
        # Check if the current MODEL_PATH exists
        current_path = "traffic-congestion-detection-9/train/weights/best.pt"
        if not os.path.exists(current_path) and model_path != current_path:
            print(f"Updating MODEL_PATH to: {model_path}")
            
            new_content = content.replace(
                f"MODEL_PATH = '{current_path}'",
                f"MODEL_PATH = '{model_path}'"
            )
            
            with open("traffic_detector.py", "w") as f:
                f.write(new_content)
            
            print("✓ MODEL_PATH updated in traffic_detector.py")
    
    except Exception as e:
        print(f"Could not update MODEL_PATH: {e}")

def download_model():
    """Main download function - tries multiple methods"""
    print("Starting model download...")
    
    # Try direct download first (fastest)
    if download_model_direct():
        return True
    
    # If that fails, the function will automatically try other methods
    return False

def check_dependencies():
    """Check if required packages are installed"""
    required_packages = ['cv2', 'numpy', 'ultralytics']
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package)
            print(f"✓ {package} is installed")
        except ImportError:
            missing_packages.append(package)
            print(f"✗ {package} is missing")
    
    if missing_packages:
        print(f"\nMissing packages: {missing_packages}")
        print("Install them with: pip install opencv-python numpy ultralytics")
        return False
    
    return True

def main():
    print("=" * 60)
    print("Traffic Congestion Detection - Roboflow Model Setup")
    print("=" * 60)
    
    # Step 1: Install roboflow
    if not install_roboflow():
        return False
    
    # Step 2: Check dependencies
    print("\nChecking dependencies...")
    if not check_dependencies():
        print("Please install missing dependencies first:")
        print("pip install -r requirements.txt")
        return False
    
    # Step 3: Download the model
    print("\nDownloading pre-trained model...")
    if not download_model():
        return False
    
    print("\n" + "=" * 60)
    print("Setup completed successfully!")
    print("You can now run: python traffic_detector.py")
    print("=" * 60)
    
    return True

if __name__ == "__main__":
    success = main()
    if not success:
        sys.exit(1)
