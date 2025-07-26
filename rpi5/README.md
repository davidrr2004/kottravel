# Traffic Congestion Detection using Pre-trained Roboflow Model

A real-time traffic congestion detection system using YOLOv8 and a pre-trained model from Roboflow Universe, optimized for Raspberry Pi 5.

## Overview

This project uses the "Traffic Congestion Detection Object Detection Dataset (v9) by SXC" from Roboflow Universe to detect and analyze traffic congestion in real-time using a camera feed.

## Features

- **Pre-trained Model**: Uses a specialized traffic congestion detection model from Roboflow
- **Real-time Detection**: Processes camera feed in real-time
- **Congestion Analysis**: Automatically categorizes traffic levels (No Traffic, Light Traffic, Moderate Congestion, High Congestion)
- **ROI Support**: Configurable Region of Interest for focused detection
- **Raspberry Pi Optimized**: Designed to run efficiently on Raspberry Pi 5
- **Interactive Controls**: Save snapshots, adjust ROI, and monitor performance

## Hardware Requirements

- Raspberry Pi 5 (4GB+ RAM recommended)
- Pi Camera or USB Camera
- MicroSD card (32GB+ recommended)
- Power supply for Pi 5

## Software Requirements

- Raspberry Pi OS (latest version)
- Python 3.8+
- Camera enabled in raspi-config

## Quick Start

### Step 1: Setup Environment

```bash
# Make setup script executable
chmod +x setup_pi.sh

# Run setup (installs all dependencies)
./setup_pi.sh

# Activate virtual environment
source traffic_env/bin/activate
```

### Step 2: Download Pre-trained Model

```bash
# Download the Roboflow model
python download_roboflow_model.py
```

### Step 3: Test Setup

```bash
# Verify everything is working
python test_setup.py
```

### Step 4: Run Traffic Detection

```bash
# Start the traffic detection system
python traffic_detector.py
```

## Usage

### Controls
- **'q'**: Quit the application
- **'s'**: Save current frame as image
- **'r'**: Reset ROI (Region of Interest)

### Configuration

Edit the configuration section in `traffic_detector.py`:

```python
# Model path (automatically set after download)
MODEL_PATH = 'traffic-congestion-detection-9/train/weights/best.pt'

# Camera settings
CAMERA_INDEX = 0  # 0 for Pi Camera, adjust for USB cameras
FRAME_WIDTH = 640
FRAME_HEIGHT = 480

# Detection settings
CONFIDENCE_THRESHOLD = 0.5

# Region of Interest [x1, y1, x2, y2]
ROI = [100, 200, 540, 400]  # Adjust for your camera view

# Congestion thresholds
LOW_CONGESTION_THRESHOLD = 3
HIGH_CONGESTION_THRESHOLD = 8
```

## About the Model

The pre-trained model comes from Roboflow Universe:
- **Dataset**: Traffic Congestion Detection Object Detection Dataset (v9) by SXC
- **Classes**: The model may detect either direct congestion states or individual vehicles
- **Architecture**: YOLOv8
- **API Key**: Included in the download script

## Troubleshooting

### Common Issues

1. **Import Errors**
   ```bash
   pip install -r requirements.txt
   ```

2. **Camera Not Found**
   - Check camera connection
   - Enable camera in `sudo raspi-config`
   - Try different CAMERA_INDEX values (0, 1, 2)

3. **Model Not Found**
   ```bash
   python download_roboflow_model.py
   ```

4. **Low Performance**
   - Reduce frame size (FRAME_WIDTH, FRAME_HEIGHT)
   - Increase confidence threshold
   - Use smaller ROI

### Performance Tips

- **Raspberry Pi 5**: Should handle 640x480 at ~10-15 FPS
- **Lower Resolution**: Use 320x240 for better performance
- **ROI Usage**: Smaller ROI improves performance
- **Confidence Threshold**: Higher values (0.6-0.7) reduce false positives

## File Structure

```
congesto/
├── traffic_detector.py          # Main detection script
├── download_roboflow_model.py   # Model download script
├── test_setup.py               # System verification
├── setup_pi.sh                 # Environment setup
├── requirements.txt            # Python dependencies
└── README.md                   # This file
```

## Customization

### Adjusting ROI
1. Run the detector: `python traffic_detector.py`
2. Press 'r' to select new ROI
3. Click and drag to select area
4. Press ENTER or SPACE to confirm

### Modifying Thresholds
Edit the threshold values in `traffic_detector.py` based on your specific use case:
- `LOW_CONGESTION_THRESHOLD`: Minimum vehicles for light congestion
- `HIGH_CONGESTION_THRESHOLD`: Vehicles count for high congestion

### Camera Settings
- Adjust `CAMERA_INDEX` for different cameras
- Modify resolution for performance vs quality trade-off
- Change FPS settings if needed

## Development

### Adding New Features
- The code is modular and well-commented
- Main detection logic is in the `TrafficDetector` class
- Extend the `analyze_congestion()` method for custom logic

### Integration
- The system can be easily integrated with IoT platforms
- Add logging, database storage, or API endpoints as needed
- Consider using MQTT for real-time alerts

## License

This project uses a pre-trained model from Roboflow Universe. Please respect the original dataset's license terms.

## Support

For issues:
1. Run `python test_setup.py` to diagnose problems
2. Check camera and model file paths
3. Verify all dependencies are installed
4. Ensure Raspberry Pi camera is enabled

## Performance Expectations

- **Raspberry Pi 5**: 10-15 FPS at 640x480
- **Detection Accuracy**: Depends on camera angle and lighting
- **Latency**: ~100-200ms per frame including processing
- **Memory Usage**: ~1-2GB RAM during operation
