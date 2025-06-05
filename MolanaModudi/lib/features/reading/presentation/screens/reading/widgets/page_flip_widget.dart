import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// A widget that wraps PageView with slow, realistic page flip animations
/// Preserves all existing PageView functionality while adding visual flair
class PageFlipWidget extends StatefulWidget {
  final PageController controller;
  final void Function(int)? onPageChanged;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final bool enabled;

  const PageFlipWidget({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    this.onPageChanged,
    this.enabled = true,
  });

  @override
  State<PageFlipWidget> createState() => _PageFlipWidgetState();
}

class _PageFlipWidgetState extends State<PageFlipWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;
  
  bool _isAnimating = false;
  int _currentPage = 0;
  double _lastPageValue = 0.0;
  DateTime? _lastAnimationTime;

  @override
  void initState() {
    super.initState();
    
    // Much slower animation - 1.2 seconds for a realistic page turn
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Gentler rotation curve
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: math.pi,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutQuad,
    ));
    
    // Subtle scale animation
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    ));
    
    // Shadow intensity
    _shadowAnimation = Tween<double>(
      begin: 0.0,
      end: 0.4,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    // Initialize current page
    _currentPage = widget.controller.hasClients ? 
      (widget.controller.page?.round() ?? 0) : 0;
    _lastPageValue = _currentPage.toDouble();
    
    // Listen to page changes - but be very conservative
    widget.controller.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPageScroll);
    _animationController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    if (!widget.enabled || !mounted || _isAnimating) return;
    
    final currentPageValue = widget.controller.page ?? _currentPage.toDouble();
    final pageChange = (currentPageValue - _lastPageValue).abs();
    
    // Only trigger on significant single page changes (not swipes)
    // Must be close to a whole number change and not too fast
    if (pageChange > 0.8 && pageChange < 1.2) {
      final now = DateTime.now();
      
      // Prevent rapid-fire animations (minimum 500ms between animations)
      if (_lastAnimationTime == null || 
          now.difference(_lastAnimationTime!).inMilliseconds > 500) {
        
        final newPage = currentPageValue.round();
        if (newPage != _currentPage && newPage >= 0 && newPage < widget.itemCount) {
          _triggerPageFlipAnimation();
          _currentPage = newPage;
          _lastAnimationTime = now;
        }
      }
    }
    
    _lastPageValue = currentPageValue;
  }

  void _triggerPageFlipAnimation() {
    if (_isAnimating) return;
    
    setState(() {
      _isAnimating = true;
    });
    
    // Light haptic feedback for the page turn
    HapticFeedback.lightImpact();
    
    // Start the slow animation
    _animationController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
        _animationController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return _buildRegularPageView();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return _buildAnimatedPageView();
      },
    );
  }

  Widget _buildRegularPageView() {
    return PageView.builder(
      controller: widget.controller,
      itemCount: widget.itemCount,
      onPageChanged: widget.onPageChanged,
      itemBuilder: widget.itemBuilder,
    );
  }

  Widget _buildAnimatedPageView() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001) // Perspective
        ..scale(_scaleAnimation.value)
        ..rotateY(_rotationAnimation.value * 0.1), // Very subtle 3D rotation
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (_isAnimating) ...[
              BoxShadow(
                color: Colors.black.withValues(alpha: _shadowAnimation.value * 0.3),
                blurRadius: 20.0 * _shadowAnimation.value,
                offset: Offset(5.0 * _shadowAnimation.value, 10.0 * _shadowAnimation.value),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: _shadowAnimation.value * 0.1),
                blurRadius: 40.0 * _shadowAnimation.value,
                offset: Offset(10.0 * _shadowAnimation.value, 20.0 * _shadowAnimation.value),
              ),
            ]
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: PageView.builder(
            controller: widget.controller,
            itemCount: widget.itemCount,
            onPageChanged: widget.onPageChanged,
            itemBuilder: widget.itemBuilder,
          ),
        ),
      ),
    );
  }
} 