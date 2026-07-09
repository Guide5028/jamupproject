import 'package:flutter/material.dart';

/// Premium "shimmer" loading placeholders.
///
/// Why skeletons instead of a spinner: a spinner says "wait" but shows nothing;
/// a skeleton previews the SHAPE of what's coming, so the app feels instant and
/// polished. Wrap any group of [SkeletonBox]es in a [Shimmer] to animate them.
///
/// No external package — the sweep is a LinearGradient slid across the boxes
/// with a ShaderMask.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFFE8E2D6); // warm light grey (matches cream theme)
    const highlight = Color(0xFFF7F3EC);
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [base, highlight, base],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: _SlideGradient(_c.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double slidePercent;
  const _SlideGradient(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Slide the highlight band from left (-width) to right (+width).
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0, 0);
  }
}

/// A single grey rounded block — the building block of any skeleton.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8E2D6),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A grid of card-shaped skeletons — drop-in placeholder for a gigs/musicians
/// grid while it loads.
class SkeletonCardGrid extends StatelessWidget {
  final int count;
  final int crossAxisCount;
  final double childAspectRatio;
  const SkeletonCardGrid({
    super.key,
    this.count = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.7,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
        ),
        itemCount: count,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8E2D6),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SkeletonBox(width: 120, height: 14),
              SizedBox(height: 8),
              SkeletonBox(width: 80, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// A horizontal row of card skeletons — for horizontally-scrolling sections
/// like the home page "Featured" / "Nearby" carousels.
class SkeletonCardRow extends StatelessWidget {
  final double height;
  final double cardWidth;
  const SkeletonCardRow({super.key, this.height = 230, this.cardWidth = 200});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SizedBox(
        height: height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (_, __) => Container(
            width: cardWidth,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E2D6),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
