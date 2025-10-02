import 'package:flutter/material.dart';

/// A safe wrapper around [Image.asset] that provides a graceful fallback
/// when the asset cannot be loaded (for example when the image file isn't
/// available in the build).
class SafeAssetImage extends StatelessWidget {
  final String assetPath;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? fallback;

  const SafeAssetImage({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, _, __) {
        if (fallback != null) {
          return fallback!;
        }
        return Container(
          alignment: alignment,
          color: Theme.of(context).colorScheme.surface,
        );
      },
    );
  }
}
