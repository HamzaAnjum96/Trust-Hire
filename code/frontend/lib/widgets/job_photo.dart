import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../services/media_store.dart';

/// Renders a photo from either the asset bundle (seed data) or local storage
/// (photos taken on this device), so callers never care which it is.
class JobPhoto extends StatelessWidget {
  const JobPhoto({
    super.key,
    required this.reference,
    required this.mediaStore,
    this.fit = BoxFit.cover,
  });

  final String reference;
  final MediaStore mediaStore;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (MediaStore.isLocal(reference)) {
      final bytes = mediaStore.read(reference);
      if (bytes == null) return const _MissingPhoto();

      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (_, _, _) => const _MissingPhoto(),
      );
    }

    return Image.asset(
      reference,
      fit: fit,
      errorBuilder: (_, _, _) => const _MissingPhoto(),
    );
  }
}

/// Shown when a photo cannot be loaded. Warm Sand with a Copper glyph, the
/// same treatment as the photo placeholder in section 27 — a gap in the
/// gallery should look intentional, not broken.
class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return ColoredBox(
      color: isLight ? BrandColours.warmSand : BrandColours.darkElevated,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 28,
          color: isLight ? BrandColours.copper : BrandColours.darkCopper,
        ),
      ),
    );
  }
}
