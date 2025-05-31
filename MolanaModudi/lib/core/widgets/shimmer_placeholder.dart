import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A generic shimmer-based placeholder that can be used as a skeleton while
/// real data is loading.
///
/// Call any of the convenience constructors like [listSkeleton] or
/// [pageSkeleton] for common layouts, or build your own via [ShimmerPlaceholder]
/// directly with a custom [child].
class ShimmerPlaceholder extends StatelessWidget {
  final Widget child;

  const ShimmerPlaceholder({super.key, required this.child});

  /// Simple line skeleton.
  factory ShimmerPlaceholder.line({double height = 16, double width = double.infinity, EdgeInsetsGeometry? margin}) {
    return ShimmerPlaceholder(
      child: Container(
        height: height,
        width: width,
        margin: margin ?? const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Skeleton that mimics a list of cards.
  factory ShimmerPlaceholder.listSkeleton({int itemCount = 6}) {
    return ShimmerPlaceholder(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          height: 120,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Skeleton suitable for an entire page with image header & text blocks.
  factory ShimmerPlaceholder.pageSkeleton() {
    return ShimmerPlaceholder(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerPlaceholder.line(width: 180, height: 20),
                  ShimmerPlaceholder.line(width: 140),
                  const SizedBox(height: 16),
                  ...List.generate(5, (_) => ShimmerPlaceholder.line()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: child,
    );
  }
}
