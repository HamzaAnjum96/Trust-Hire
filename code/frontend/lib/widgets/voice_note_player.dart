import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/tokens.dart';
import '../services/media_store.dart';

/// Plays a job's voice note.
///
/// Voice is a first-class content type (section 26), so this is a prominent
/// control rather than a small icon: Warm Sand surface, a burgundy play
/// button, and a copper waveform that fills as it plays. Labels are the plain
/// ones the guidelines ask for — "Listen", "Record Again" — never "Play Audio
/// Asset".
class VoiceNotePlayer extends StatefulWidget {
  const VoiceNotePlayer({
    super.key,
    required this.reference,
    required this.mediaStore,
    this.duration,
  });

  /// Asset path or `local:` reference for the recording.
  final String reference;
  final MediaStore mediaStore;

  /// Known length, used to draw the scrubber before playback starts.
  final Duration? duration;

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  late final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription<void>> _subscriptions = [];

  Duration _position = Duration.zero;
  Duration? _total;
  bool _isPlaying = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _total = widget.duration;

    _subscriptions.addAll([
      _player.onPositionChanged.listen((position) {
        if (mounted) setState(() => _position = position);
      }),
      _player.onDurationChanged.listen((duration) {
        if (mounted) setState(() => _total = duration);
      }),
      _player.onPlayerStateChanged.listen((state) {
        if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
      }),
      _player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _position = Duration.zero;
          });
        }
      }),
    ]);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_failed) return;

    try {
      if (_isPlaying) {
        await _player.pause();
        return;
      }

      if (_position == Duration.zero) {
        await _player.play(_source());
      } else {
        await _player.resume();
      }
    } catch (error) {
      if (kDebugMode) debugPrint('Voice note playback failed: $error');
      if (mounted) setState(() => _failed = true);
    }
  }

  Source _source() {
    if (MediaStore.isLocal(widget.reference)) {
      final bytes = widget.mediaStore.read(widget.reference);
      if (bytes == null) throw StateError('Recording is missing');
      return BytesSource(bytes);
    }
    // AssetSource paths are relative to the assets/ folder.
    return AssetSource(MediaStore.assetKeyFor(widget.reference));
  }

  double get _progress {
    final total = _total;
    if (total == null || total.inMilliseconds == 0) return 0;
    return (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    if (_failed) {
      return _Surface(
        isLight: isLight,
        child: Row(
          children: [
            const Icon(
              Icons.mic_off_outlined,
              color: BrandColours.errorRed,
              size: 22,
            ),
            const SizedBox(width: BrandSizing.spaceSm + 4),
            Expanded(
              child: Text(
                'This voice note could not be played.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return _Surface(
      isLight: isLight,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: _isPlaying ? 'Pause' : 'Listen',
            child: Material(
              color: theme.colorScheme.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _toggle,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: BrandSizing.touchTargetPreferred,
                  height: BrandSizing.touchTargetPreferred,
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: theme.colorScheme.onPrimary,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: BrandSizing.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      // Section 26 wording.
                      _isPlaying ? 'Playing' : 'Voice note',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${Format.duration(_position)} / '
                      '${Format.duration(_total)}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: BrandSizing.spaceSm),
                SizedBox(
                  height: 28,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _WaveformPainter(
                      seed: widget.reference.hashCode,
                      progress: _progress,
                      playedColour: isLight
                          ? BrandColours.copper
                          : BrandColours.darkCopper,
                      remainingColour: isLight
                          ? BrandColours.stone
                          : BrandColours.slate,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        // Section 26 — a recorded note sits on Warm Sand.
        color: isLight ? BrandColours.warmSand : BrandColours.darkElevated,
        borderRadius: BrandRadius.mediumAll,
      ),
      child: child,
    );
  }
}

/// A deterministic waveform.
///
/// Decoding the audio to draw a true waveform is well beyond a POC, so the
/// bars are derived from a hash of the reference: stable for a given
/// recording, different between recordings, and it fills as playback advances.
class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.seed,
    required this.progress,
    required this.playedColour,
    required this.remainingColour,
  });

  final int seed;
  final double progress;
  final Color playedColour;
  final Color remainingColour;

  @override
  void paint(Canvas canvas, Size size) {
    const barWidth = 3.0;
    const gap = 3.0;
    final count = (size.width / (barWidth + gap)).floor();
    if (count <= 0) return;

    final random = math.Random(seed);
    final playedBars = (count * progress).round();

    for (var i = 0; i < count; i++) {
      // A gentle envelope so the shape reads as speech rather than noise.
      final envelope = 0.35 + 0.65 * math.sin((i / count) * math.pi);
      final height = (0.25 + random.nextDouble() * 0.75) * envelope * size.height;

      final left = i * (barWidth + gap);
      final top = (size.height - height) / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, height),
          const Radius.circular(1.5),
        ),
        Paint()..color = i < playedBars ? playedColour : remainingColour,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.seed != seed ||
      oldDelegate.playedColour != playedColour;
}
