import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// AppNetworkImage
/// ---------------
/// The ONE place the app loads remote images, configured for smooth scrolling.
///
/// Why this exists (the performance lesson):
///   • Caching — CachedNetworkImage stores each image on disk AND in memory,
///     so it's downloaded and decoded ONCE and then reused. Plain
///     Image.network re-decodes on every rebuild/scroll, which is the main
///     cause of list jank.
///   • Downscaling (memCacheWidth) — a huge photo shown in a small card is
///     decoded at roughly the size it's displayed, not its full resolution.
///     Decoding full-res images is the single most expensive thing a
///     scrolling list does, so this is where most of the smoothness comes from.
///
/// It keeps every call site's existing look by accepting optional [placeholder]
/// and [errorWidget] — nothing about your fallbacks or loading states is lost.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  /// The logical width the image is shown at (e.g. card width). We multiply by
  /// the device pixel ratio to pick a sensible decode size. Leave null to skip
  /// downscaling (use only for full-screen images).
  final double? displayWidth;

  /// Shown while the image downloads. If null, nothing is shown (the space is
  /// simply empty until the image fades in).
  final Widget? placeholder;

  /// Shown when the URL is empty or the image fails to load.
  final Widget? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.displayWidth,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // A neutral default if a caller doesn't supply its own error widget.
    final fallback = errorWidget ??
        Container(
          color: const Color(0xFF2A2A2A),
          child: const Center(
            child: Icon(Icons.image_not_supported,
                size: 40, color: Colors.white54),
          ),
        );

    // No URL → don't even attempt a network call; show the fallback.
    if (url.trim().isEmpty) return fallback;

    int? memCacheWidth;
    if (displayWidth != null) {
      final dpr = MediaQuery.of(context).devicePixelRatio;
      memCacheWidth = (displayWidth! * dpr).round();
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: memCacheWidth,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder:
          placeholder == null ? null : (context, _) => placeholder!,
      errorWidget: (context, _, __) => fallback,
    );
  }
}
