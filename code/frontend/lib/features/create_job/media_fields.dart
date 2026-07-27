import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/tokens.dart';
import '../../services/media_store.dart';
import '../../widgets/job_photo.dart';
import 'job_draft_controller.dart';

/// Recording a voice note.
///
/// Voice before keyboard: this is the first and largest control on the form.
/// Labels follow section 26 — "Record", "Recording…", "Voice Note Added" —
/// never "Capture Audio".
class VoiceRecorderField extends StatefulWidget {
  const VoiceRecorderField({super.key, required this.draft});

  final JobDraftController draft;

  @override
  State<VoiceRecorderField> createState() => _VoiceRecorderFieldState();
}

class _VoiceRecorderFieldState extends State<VoiceRecorderField> {
  Timer? _ticker;

  @override
  void didUpdateWidget(VoiceRecorderField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
  }

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  /// Drives the elapsed-time readout while recording.
  void _syncTicker() {
    if (widget.draft.isRecording && _ticker == null) {
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (mounted) setState(() {});
      });
    } else if (!widget.draft.isRecording) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final draft = widget.draft;

    if (draft.microphoneUnavailable) {
      return _Surface(
        isLight: isLight,
        child: Row(
          children: [
            const Icon(
              Icons.mic_off_outlined,
              color: BrandColours.informationBlue,
              size: 22,
            ),
            const SizedBox(width: BrandSizing.spaceSm + 4),
            Expanded(
              child: Text(
                'Microphone access is off. You can still add a photo or type '
                'a short message.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    if (draft.isRecording) {
      return _Surface(
        isLight: isLight,
        child: Row(
          children: [
            // Section 26 — recording turns the control Error Red.
            _RoundButton(
              colour: BrandColours.errorRed,
              icon: Icons.stop,
              label: 'Stop recording',
              onTap: draft.stopRecording,
            ),
            const SizedBox(width: BrandSizing.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recording…',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    Format.duration(draft.recordingElapsed),
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: draft.cancelRecording,
              child: const Text('Discard'),
            ),
          ],
        ),
      );
    }

    if (draft.hasVoiceNote) {
      return _Surface(
        isLight: isLight,
        child: Row(
          children: [
            const Icon(
              Icons.graphic_eq,
              color: BrandColours.copper,
              size: 26,
            ),
            const SizedBox(width: BrandSizing.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Voice Note Added',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    Format.duration(draft.voiceDuration),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: draft.startRecording,
              child: const Text('Record Again'),
            ),
            IconButton(
              onPressed: draft.removeVoiceNote,
              icon: const Icon(Icons.close),
              tooltip: 'Remove voice note',
            ),
          ],
        ),
      );
    }

    return _Surface(
      isLight: isLight,
      child: Row(
        children: [
          _RoundButton(
            colour: BrandColours.copper,
            icon: Icons.mic,
            label: 'Record a voice note',
            onTap: draft.startRecording,
          ),
          const SizedBox(width: BrandSizing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tell people about the job',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  // Section 33 copy.
                  'Speak naturally. You do not need to prepare anything.',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Adding photos. Large tappable thumbnails, never a caption requirement.
class PhotoField extends StatelessWidget {
  const PhotoField({
    super.key,
    required this.draft,
    required this.mediaStore,
  });

  final JobDraftController draft;
  final MediaStore mediaStore;

  static const _tileSize = 96.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    return SizedBox(
      height: _tileSize,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _AddTile(
            icon: Icons.photo_camera_outlined,
            label: 'Take Photo',
            isLight: isLight,
            onTap: draft.takePhoto,
          ),
          const SizedBox(width: BrandSizing.spaceSm),
          _AddTile(
            icon: Icons.photo_library_outlined,
            label: 'Choose Photo',
            isLight: isLight,
            onTap: draft.choosePhoto,
          ),
          for (var i = 0; i < draft.photos.length; i++) ...[
            const SizedBox(width: BrandSizing.spaceSm),
            _PhotoTile(
              photo: draft.photos[i],
              mediaStore: mediaStore,
              onRemove: () => draft.removePhotoAt(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.icon,
    required this.label,
    required this.isLight,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isLight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isLight ? BrandColours.copper : BrandColours.darkCopper;

    return InkWell(
      onTap: onTap,
      borderRadius: BrandRadius.mediumAll,
      child: Container(
        width: PhotoField._tileSize,
        padding: const EdgeInsets.all(BrandSizing.spaceSm),
        decoration: BoxDecoration(
          // Section 27 — Warm Sand tile with a dashed copper edge.
          color: isLight ? BrandColours.warmSand : BrandColours.darkElevated,
          borderRadius: BrandRadius.mediumAll,
          border: Border.all(color: accent.withValues(alpha: 0.6)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: accent, size: 26),
            const SizedBox(height: BrandSizing.spaceXs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.mediaStore,
    required this.onRemove,
  });

  final DraftPhoto photo;
  final MediaStore mediaStore;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: PhotoField._tileSize,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BrandRadius.mediumAll,
              child: photo.isNew
                  ? Image.memory(photo.bytes!, fit: BoxFit.cover)
                  : JobPhoto(
                      reference: photo.reference!,
                      mediaStore: mediaStore,
                    ),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: Material(
              color: BrandColours.ink.withValues(alpha: 0.6),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: BrandColours.white,
                    semanticLabel: 'Remove photo',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.colour,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Color colour;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: colour,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: BrandSizing.touchTargetPreferred,
            height: BrandSizing.touchTargetPreferred,
            child: Icon(icon, color: BrandColours.white, size: 26),
          ),
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.isLight, required this.child});

  final bool isLight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BrandSizing.spaceSm + 4),
      decoration: BoxDecoration(
        color: isLight ? BrandColours.warmSand : BrandColours.darkElevated,
        borderRadius: BrandRadius.mediumAll,
      ),
      child: child,
    );
  }
}
