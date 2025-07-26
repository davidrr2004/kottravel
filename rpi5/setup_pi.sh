#!/bin/bash

# Setup script for Raspberry Pi 5 - Traffic Congestion Detection
# This script installs all required dependencies and sets up the environment

echo "=================================================="
echo "Traffic Congestion Detection Setup for Raspberry Pi 5"
echo "=================================================="

# Update system packages
echo "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Python dependencies
echo "Installing Python packages..."
sudo apt install -y python3-pip python3-venv python3-opencv

# Create virtual environment
echo "Creating virtual environment..."
python3 -m venv traffic_env
source traffic_env/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install Python packages
echo "Installing required Python packages..."
pip install opencv-python==4.8.1.78
pip install ultralytics==8.0.196
pip install roboflow==1.1.9

# Install PyTorch CPU version (lighter for Pi)
echo "Installing PyTorch CPU version..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# Install additional dependencies
pip install numpy matplotlib Pillow

echo "=================================================="
echo "Setup completed successfully!"
echo "To activate the environment in future sessions:"
echo "source traffic_env/bin/activate"
echo ""
echo "Next steps:"
echo "1. Run: python download_roboflow_model.py"
echo "2. Then run: python traffic_detector.py"
echo "=================================================="
