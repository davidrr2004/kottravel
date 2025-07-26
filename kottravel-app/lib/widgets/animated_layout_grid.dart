import 'package:flutter/material.dart';

class AnimatedLayoutGrid extends StatefulWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  final bool isAnimating;

  const AnimatedLayoutGrid({
    super.key,
    this.size = 24.0,
    this.color = Colors.white,
    this.strokeWidth = 2.0,
    this.isAnimating = false,
  });

  @override
  State<AnimatedLayoutGrid> createState() => _AnimatedLayoutGridState();
}

class _AnimatedLayoutGridState extends State<AnimatedLayoutGrid>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _animations;
  bool _lastAnimatingState = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600), // Match navbar animation duration
      vsync: this,
    );

    _initializeAnimations();
    
    // Set initial state
    _lastAnimatingState = widget.isAnimating;
    if (widget.isAnimating) {
      _controller.forward();
    }
  }

  void _initializeAnimations() {
    // Define the clockwise rotation positions for each box - smaller movements
    final positions = [
      const Offset(6.0, 0.0),    // Smaller movements to reduce shake
      const Offset(0.0, 6.0),    
      const Offset(-6.0, 0.0),   
      const Offset(0.0, -6.0),   
    ];

    _animations = List.generate(4, (index) {
      return Tween<Offset>(
        begin: Offset.zero,
        end: positions[index],
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,        // Match navbar's elegant curve
        reverseCurve: Curves.easeInQuart, // Smoother reverse curve
      ));
    });
  }

  @override
  void didUpdateWidget(AnimatedLayoutGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != _lastAnimatingState) {
      _lastAnimatingState = widget.isAnimating;
      if (widget.isAnimating) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: LayoutGridPainter(
              color: widget.color,
              strokeWidth: widget.strokeWidth,
              animations: _animations,
            ),
          );
        },
      ),
    );
  }
}

class LayoutGridPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<Animation<Offset>> animations;

  LayoutGridPainter({
    required this.color,
    required this.strokeWidth,
    required this.animations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true; // Add anti-aliasing for smoother edges

    // Scale factor to fit the 24x24 viewBox into the given size
    final scaleX = size.width / 24;
    final scaleY = size.height / 24;
    
    // Box size and positions (scaled)
    final boxSize = 7.0;
    final cornerRadius = 1.0;
    
    // Original positions of the four boxes
    final basePositions = [
      Offset(3 * scaleX, 3 * scaleY),       // Top left
      Offset(14 * scaleX, 3 * scaleY),      // Top right
      Offset(14 * scaleX, 14 * scaleY),     // Bottom right
      Offset(3 * scaleX, 14 * scaleY),      // Bottom left
    ];

    // Draw each animated box
    for (int i = 0; i < 4; i++) {
      final basePos = basePositions[i];
      final animOffset = animations[i].value;
      
      // Apply animation offset (scaled and clamped to prevent overshooting)
      final currentPos = Offset(
        (basePos.dx + (animOffset.dx * scaleX * 0.3)).clamp(0.0, size.width - (boxSize * scaleX)),
        (basePos.dy + (animOffset.dy * scaleY * 0.3)).clamp(0.0, size.height - (boxSize * scaleY)),
      );
      
      // Create rounded rectangle with pixel-perfect positioning
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          currentPos.dx.roundToDouble(),
          currentPos.dy.roundToDouble(),
          (boxSize * scaleX).roundToDouble(),
          (boxSize * scaleY).roundToDouble(),
        ),
        Radius.circular(cornerRadius * scaleX),
      );
      
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(LayoutGridPainter oldDelegate) {
    return oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth ||
           oldDelegate.animations != animations;
  }
}
