import 'package:flutter/material.dart';
import '../services/emergency_service.dart';

class EmergencyButton extends StatefulWidget {
  final String cameraId;

  const EmergencyButton({Key? key, this.cameraId = 'camera_001'})
    : super(key: key);

  @override
  State<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends State<EmergencyButton>
    with TickerProviderStateMixin {
  bool _isEmergencyActive = false;
  bool _isLoading = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkEmergencyStatus();

    // Set up pulse animation for emergency state
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkEmergencyStatus() async {
    final isActive = await EmergencyService.isEmergencyActive(widget.cameraId);
    setState(() {
      _isEmergencyActive = isActive;
    });

    if (isActive) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }
  }

  Future<void> _toggleEmergency() async {
    setState(() {
      _isLoading = true;
    });

    bool success;
    if (_isEmergencyActive) {
      success = await EmergencyService.deactivateEmergencySignal(
        widget.cameraId,
      );
    } else {
      success = await EmergencyService.activateEmergencySignal(widget.cameraId);
    }

    if (success) {
      setState(() {
        _isEmergencyActive = !_isEmergencyActive;
      });

      if (_isEmergencyActive) {
        _pulseController.repeat(reverse: true);
        _showSnackBar('Emergency signal activated!', Colors.red);
      } else {
        _pulseController.stop();
        _showSnackBar('Emergency signal deactivated', Colors.green);
      }
    } else {
      _showSnackBar('Failed to update emergency status', Colors.orange);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isEmergencyActive ? _pulseAnimation.value : 1.0,
          child: Container(
            margin: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main Emergency Button
                GestureDetector(
                  onTap: _isLoading ? null : _toggleEmergency,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _isEmergencyActive ? Colors.red : Colors.red.shade700,
                      boxShadow: [
                        BoxShadow(
                          color:
                              _isEmergencyActive
                                  ? Colors.red.withOpacity(0.6)
                                  : Colors.black.withOpacity(0.3),
                          blurRadius: _isEmergencyActive ? 20 : 10,
                          spreadRadius: _isEmergencyActive ? 5 : 2,
                        ),
                      ],
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child:
                        _isLoading
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Icon(
                              _isEmergencyActive
                                  ? Icons.warning
                                  : Icons.emergency,
                              size: 50,
                              color: Colors.white,
                            ),
                  ),
                ),

                const SizedBox(height: 12),

                // Status Text
                Text(
                  _isEmergencyActive ? 'EMERGENCY ACTIVE' : 'EMERGENCY',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isEmergencyActive ? Colors.red : Colors.black87,
                  ),
                ),

                const SizedBox(height: 8),

                // Action Text
                Text(
                  _isEmergencyActive ? 'Tap to deactivate' : 'Tap to activate',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 16),

                // Camera ID Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Camera: ${widget.cameraId}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
