import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

/// Captures photos and voice notes and hands back raw bytes.
///
/// Bytes rather than file paths, deliberately: a recording or picked image on
/// web is a blob URL that stops resolving once the page reloads, so anything
/// captured has to be read out immediately and stored by [MediaStore]. Reading
/// bytes here keeps every platform on the same path.
class CaptureService {
  CaptureService({ImagePicker? picker, AudioRecorder? recorder})
    : _picker = picker ?? ImagePicker(),
      _recorder = recorder ?? AudioRecorder();

  final ImagePicker _picker;
  final AudioRecorder _recorder;

  /// Capture settings are capped here rather than downscaled later: photos go
  /// into local storage as base64, and a full-resolution phone camera image
  /// would be tens of megabytes of string.
  static const _maxWidth = 1600.0;
  static const _maxHeight = 1600.0;
  static const _quality = 72;

  /// Takes a photo with the camera, or null if the user backs out.
  Future<Uint8List?> takePhoto() => _pick(ImageSource.camera);

  /// Chooses an existing photo, or null if the user backs out.
  Future<Uint8List?> choosePhoto() => _pick(ImageSource.gallery);

  Future<Uint8List?> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: _maxWidth,
        maxHeight: _maxHeight,
        imageQuality: _quality,
      );
      if (file == null) return null;
      return await file.readAsBytes();
    } catch (error) {
      if (kDebugMode) debugPrint('Photo capture failed: $error');
      return null;
    }
  }

  Future<bool> hasMicrophonePermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (error) {
      if (kDebugMode) debugPrint('Microphone permission check failed: $error');
      return false;
    }
  }

  /// Begins recording. Returns false when the microphone is unavailable, so
  /// the caller can explain rather than appear to record nothing.
  Future<bool> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) return false;

      await _recorder.start(
        // AAC in an m4a container plays back on every target, including web.
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000),
        path: '',
      );
      return true;
    } catch (error) {
      if (kDebugMode) debugPrint('Recording failed to start: $error');
      return false;
    }
  }

  /// Stops recording and returns the audio, or null if nothing was captured.
  Future<Uint8List?> stopRecording() async {
    try {
      final location = await _recorder.stop();
      if (location == null) return null;
      return await _readRecording(location);
    } catch (error) {
      if (kDebugMode) debugPrint('Recording failed to stop: $error');
      return null;
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _recorder.cancel();
    } catch (error) {
      if (kDebugMode) debugPrint('Recording failed to cancel: $error');
    }
  }

  Future<Uint8List?> _readRecording(String location) async {
    // On web `stop` yields a blob URL; on mobile, a file path. XFile reads
    // both, which keeps this one code path.
    final file = XFile(location);
    final bytes = await file.readAsBytes();
    return bytes.isEmpty ? null : bytes;
  }

  Future<void> dispose() => _recorder.dispose();
}
