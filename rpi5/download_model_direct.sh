#!/bin/bash

# Direct download script for Roboflow traffic congestion model
# Alternative to the Python download script

echo "=================================================="
echo "Downloading Traffic Congestion Model - Direct Method"
echo "=================================================="

# Check if curl is available
if ! command -v curl &> /dev/null; then
    echo "curl not found. Installing..."
    sudo apt update && sudo apt install -y curl
fi

# Check if unzip is available  
if ! command -v unzip &> /dev/null; then
    echo "unzip not found. Installing..."
    sudo apt update && sudo apt install -y unzip
fi

echo "Downloading model from Roboflow..."
curl -L "https://universe.roboflow.com/ds/gRRYEMu1HL?key=Poykx80Izj" > roboflow.zip

if [ $? -eq 0 ]; then
    echo "Download successful! Extracting files..."
    unzip roboflow.zip
    
    if [ $? -eq 0 ]; then
        echo "Extraction successful! Cleaning up..."
        rm roboflow.zip
        
        echo "Looking for model files..."
        find . -name "*.pt" -type f
        
        echo "=================================================="
        echo "Model download completed!"
        echo "You can now run: python traffic_detector.py"
        echo "=================================================="
    else
        echo "Error: Failed to extract files"
        exit 1
    fi
else
    echo "Error: Failed to download model"
    echo "Please check your internet connection"
    exit 1
fi
