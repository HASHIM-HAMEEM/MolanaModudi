import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A focus mode overlay that dims content except focused sections
class FocusModeOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final bool enabled;
  final ScrollController scrollController;

  const FocusModeOverlay({
    super.key,
    required this.child,
    required this.enabled,
    required this.scrollController,
  });

  @override
  ConsumerState<FocusModeOverlay> createState() => _FocusModeOverlayState();
}

class _FocusModeOverlayState extends ConsumerState<FocusModeOverlay>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  Rect? _focusRect;
  bool _isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Initialize focus mode if enabled
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _activateFocusMode();
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FocusModeOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _activateFocusMode();
      } else {
        _deactivateFocusMode();
      }
    }
  }

  void _activateFocusMode() {
    if (!mounted) return;
    
    print('🔍 Focus mode: Activating overlay');
    
    setState(() {
      _isOverlayVisible = true;
    });
    
    // Set default focus area
    _setDefaultFocus();
    _animationController.forward();
  }

  void _deactivateFocusMode() {
    if (!mounted) return;
    
    print('🔍 Focus mode: Deactivating overlay');
    
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isOverlayVisible = false;
          _focusRect = null;
        });
      }
    });
  }

  void _setDefaultFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;
        final focusHeight = size.height * 0.5; // Larger focus area
        final focusTop = (size.height - focusHeight) / 2;
        
        setState(() {
          _focusRect = Rect.fromLTWH(
            16, // Small padding from edges
            focusTop,
            size.width - 32,
            focusHeight,
          );
        });
        
        print('🔍 Focus mode: Set default focus rect: $_focusRect');
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content - always scrollable and always on top for interactions
        widget.child,
        
        // Focus mode overlay (only show when enabled) - behind the content
        if (widget.enabled && _isOverlayVisible)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return IgnorePointer(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: CustomPaint(
                      painter: FocusModePainter(
                        focusRect: _focusRect,
                        opacity: _fadeAnimation.value * 0.6, // Lighter dimming for better readability
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Painter for the focus mode overlay effect
class FocusModePainter extends CustomPainter {
  final Rect? focusRect;
  final double opacity;

  const FocusModePainter({
    required this.focusRect,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (focusRect == null || opacity <= 0) return;

    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: opacity);

    // Create a path that covers everything except the focus area
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        focusRect!,
        const Radius.circular(12),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Add a subtle glow around the focus area
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawRRect(
      RRect.fromRectAndRadius(focusRect!, const Radius.circular(12)),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(FocusModePainter oldDelegate) {
    return oldDelegate.focusRect != focusRect ||
           oldDelegate.opacity != opacity;
  }
} 