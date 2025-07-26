import 'package:flutter/material.dart';
import '../services/congestion_detection_service.dart';

class CongestionMarker extends StatefulWidget {
  final CongestionAlert alert;
  final VoidCallback? onTap;

  const CongestionMarker({super.key, required this.alert, this.onTap});

  @override
  State<CongestionMarker> createState() => _CongestionMarkerState();
}

class _CongestionMarkerState extends State<CongestionMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  bool _showText = true;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 500,
      ), // Duration for fade out animation
    );

    // Create opacity animation from 1.0 to 0.0
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Start a delayed task to hide the text
    Future.delayed(const Duration(seconds: 5), () {
      // Text stays visible for 5 seconds
      if (mounted) {
        _controller.forward().then((_) {
          if (mounted) {
            setState(() {
              _showText = false;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show markers for medium (level 2) and high (level 3) congestion
    if (widget.alert.level == CongestionLevel.low) {
      return const SizedBox.shrink(); // Don't show any marker
    }

    // Use Column for better vertical layout control
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 60,
        height: 80, // Increased height to ensure text has room
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circle marker
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _getCongestionColor(
                  widget.alert.level,
                ).withOpacity(0.85),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.traffic, color: Colors.white, size: 20),
            ),
            // Text label below the circle with some spacing
            const SizedBox(height: 4),
            // Show the text container only if _showText is true
            if (_showText)
              FadeTransition(
                opacity: _opacityAnimation,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Text(
                    _getCongestionText(widget.alert.level),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCongestionColor(CongestionLevel level) {
    switch (level) {
      case CongestionLevel.low:
        return Colors.green;
      case CongestionLevel.medium:
        return Colors.orange;
      case CongestionLevel.high:
        return Colors.red;
      case CongestionLevel.severe:
        return Colors.purple;
    }
  }

  String _getCongestionText(CongestionLevel level) {
    switch (level) {
      case CongestionLevel.low:
        return 'Light Traffic';
      case CongestionLevel.medium:
        return 'Moderate Traffic';
      case CongestionLevel.high:
        return 'Heavy Traffic';
      case CongestionLevel.severe:
        return 'Severe Congestion';
    }
  }
}

class CongestionAlertDialog extends StatelessWidget {
  final CongestionAlert alert;

  const CongestionAlertDialog({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    // Format timestamp
    final timeString =
        '${alert.timestamp.hour}:${alert.timestamp.minute.toString().padLeft(2, '0')}';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.traffic, color: _getCongestionColor(alert.level)),
          const SizedBox(width: 8),
          Text(
            'Traffic Alert',
            style: TextStyle(color: _getCongestionColor(alert.level)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getCongestionText(alert.level),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(alert.description),
          const SizedBox(height: 12),
          Text(
            'Reported at $timeString',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Color _getCongestionColor(CongestionLevel level) {
    switch (level) {
      case CongestionLevel.low:
        return Colors.green;
      case CongestionLevel.medium:
        return Colors.orange;
      case CongestionLevel.high:
        return Colors.red;
      case CongestionLevel.severe:
        return Colors.purple;
    }
  }

  String _getCongestionText(CongestionLevel level) {
    switch (level) {
      case CongestionLevel.low:
        return 'Light Traffic';
      case CongestionLevel.medium:
        return 'Moderate Traffic';
      case CongestionLevel.high:
        return 'Heavy Traffic';
      case CongestionLevel.severe:
        return 'Severe Congestion';
    }
  }
}
