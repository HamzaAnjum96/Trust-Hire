import 'package:flutter/material.dart';

import '../../core/motion.dart';
import '../../core/tokens.dart';
import '../../services/media_store.dart';
import '../../widgets/job_photo.dart';

/// A swipeable gallery of a job's photos, with a full-screen viewer.
///
/// Pictures before paragraphs — photos are given real space rather than being
/// reduced to thumbnails, and captions are never required (section 27).
class PhotoGallery extends StatefulWidget {
  const PhotoGallery({
    super.key,
    required this.photos,
    required this.mediaStore,
    this.height = 220,
  });

  final List<String> photos;
  final MediaStore mediaStore;
  final double height;

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  late final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openViewer(int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PhotoViewer(
          photos: widget.photos,
          mediaStore: widget.mediaStore,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: ClipRRect(
            borderRadius: BrandRadius.largeAll,
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _openViewer(index),
                child: Semantics(
                  button: true,
                  label: 'Photo ${index + 1} of ${widget.photos.length}',
                  child: JobPhoto(
                    reference: widget.photos[index],
                    mediaStore: widget.mediaStore,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.photos.length > 1) ...[
          const SizedBox(height: BrandSizing.spaceSm + 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.photos.length; i++)
                AnimatedContainer(
                  duration: Motion.fast(context),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _page
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  const _PhotoViewer({
    required this.photos,
    required this.mediaStore,
    required this.initialIndex,
  });

  final List<String> photos;
  final MediaStore mediaStore;
  final int initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColours.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: BrandColours.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: photos.length,
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(
            child: JobPhoto(
              reference: photos[index],
              mediaStore: mediaStore,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
