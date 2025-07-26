# Quick Start Guide for Traffic Congestion Detection

## For Raspberry Pi 5 Users

### 1. Initial Setup (One-time)

```bash
# Clone or download the project files to your Pi
# Navigate to the project directory
cd /path/to/congesto

# Make setup script executable
chmod +x setup_pi.sh

# Run the automated setup
./setup_pi.sh
```

### 2. Activate Environment

```bash
# Every time you want to use the system
source traffic_env/bin/activate
```

### 3. Download Model (One-time)

```bash
# Download the pre-trained model from Roboflow
python download_roboflow_model.py
```

### 4. Test Everything

```bash
# Verify the setup works
python test_setup.py
```

### 5. Run Traffic Detection

```bash
# Start the main application
python traffic_detector.py
```

## Controls

- **'q'**: Quit
- **'s'**: Save screenshot
- **'r'**: Reset detection area

## Troubleshooting

If something doesn't work:

1. **Check test results**: `python test_setup.py`
2. **Camera issues**: Enable camera in `sudo raspi-config`
3. **Import errors**: Re-run `./setup_pi.sh`
4. **Model missing**: Re-run `python download_roboflow_model.py`

## Expected Performance

- **Frame Rate**: 10-15 FPS on Raspberry Pi 5
- **Resolution**: 640x480 (adjustable)
- **Detection**: Real-time vehicle/congestion detection
- **Congestion Levels**: No Traffic → Light → Moderate → High

## Quick Configuration

Edit these values in `traffic_detector.py` if needed:

```python
CAMERA_INDEX = 0        # Change if using USB camera
CONFIDENCE_THRESHOLD = 0.5  # Lower = more detections
ROI = [100, 200, 540, 400]  # Detection area [x1,y1,x2,y2]
```

That's it! You should now have a working traffic congestion detection system.
