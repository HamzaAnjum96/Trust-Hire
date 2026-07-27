// The fields below are private, so they cannot be initialising formals on
// named parameters — and named parameters are the right shape for a
// constructor with this many collaborators.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/job.dart';
import '../../models/job_type.dart';
import '../../services/capture_service.dart';
import '../../services/media_store.dart';

/// A photo on the draft — either already stored, or just captured and waiting
/// to be written when the job is saved.
@immutable
class DraftPhoto {
  const DraftPhoto.existing(this.reference) : bytes = null;
  const DraftPhoto.captured(this.bytes) : reference = null;

  final String? reference;
  final Uint8List? bytes;

  bool get isNew => bytes != null;
}

/// Why a draft cannot be saved yet.
enum DraftProblem {
  /// Nothing at all describes the work.
  nothingToShow,
}

/// Holds a job being written, for both creating and editing.
///
/// The governing rule is design principle 2: nothing is required except that
/// the job say *something* — a voice note, a photo, or a few words, any one of
/// which is enough on its own. There is no field-level validation anywhere in
/// here, and never an asterisk.
class JobDraftController extends ChangeNotifier {
  JobDraftController({
    required MediaStore mediaStore,
    required CaptureService capture,
    required JobLocation initialLocation,
    Job? editing,
    Uuid uuid = const Uuid(),
  }) : _mediaStore = mediaStore,
       _capture = capture,
       _uuid = uuid,
       _editing = editing,
       _location = editing?.location ?? initialLocation,
       _radiusMetres = editing?.radiusMetres ?? 1000,
       _title = editing?.title ?? '',
       _type = editing?.type,
       _description = editing?.shortDescription ?? '',
       _contactNumber = editing?.contactNumber ?? '',
       _scheduledTime = editing?.scheduledTime,
       _voiceReference = editing?.voiceNotePath,
       _voiceDuration = editing?.voiceNoteDuration,
       _photos = [
         for (final reference in editing?.photoPaths ?? const <String>[])
           DraftPhoto.existing(reference),
       ];

  final MediaStore _mediaStore;
  final CaptureService _capture;
  final Uuid _uuid;
  final Job? _editing;

  JobLocation _location;
  double _radiusMetres;
  String _title;
  JobType? _type;
  String _description;
  String _contactNumber;
  DateTime? _scheduledTime;

  final List<DraftPhoto> _photos;

  String? _voiceReference;
  Uint8List? _voiceBytes;
  Duration? _voiceDuration;

  bool _isRecording = false;
  DateTime? _recordingStartedAt;
  bool _isSaving = false;
  String? _errorMessage;
  bool _microphoneUnavailable = false;

  bool get isEditing => _editing != null;
  JobLocation get location => _location;
  double get radiusMetres => _radiusMetres;
  String get title => _title;
  JobType? get type => _type;
  String get description => _description;
  String get contactNumber => _contactNumber;
  DateTime? get scheduledTime => _scheduledTime;
  List<DraftPhoto> get photos => List.unmodifiable(_photos);
  bool get hasVoiceNote => _voiceReference != null || _voiceBytes != null;
  Duration? get voiceDuration => _voiceDuration;
  String? get voiceReference => _voiceReference;
  Uint8List? get voiceBytes => _voiceBytes;
  bool get isRecording => _isRecording;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get microphoneUnavailable => _microphoneUnavailable;

  /// How long the current recording has been running.
  Duration get recordingElapsed {
    final startedAt = _recordingStartedAt;
    if (startedAt == null) return Duration.zero;
    return DateTime.now().difference(startedAt);
  }

  /// True once the draft says something — anything.
  bool get hasContent =>
      _type != null ||
      _title.trim().isNotEmpty ||
      _description.trim().isNotEmpty ||
      hasVoiceNote ||
      _photos.isNotEmpty;

  /// What is stopping a save, or null when it can go ahead.
  DraftProblem? get problem => hasContent ? null : DraftProblem.nothingToShow;

  bool get canSave => problem == null && !_isSaving && !_isRecording;

  void setLocation(JobLocation value) {
    if (_location == value) return;
    _location = value;
    notifyListeners();
  }

  void setRadius(double metres) {
    if (_radiusMetres == metres) return;
    _radiusMetres = metres;
    notifyListeners();
  }

  /// Sets the kind of work, or clears it. Never required — an untyped job is
  /// normal, and tapping the selected type again unsets it.
  void setType(JobType? value) {
    if (_type == value) return;
    _type = value;
    notifyListeners();
  }

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void setContactNumber(String value) {
    _contactNumber = value;
    notifyListeners();
  }

  void setScheduledTime(DateTime? value) {
    _scheduledTime = value;
    notifyListeners();
  }

  Future<void> takePhoto() => _addPhoto(_capture.takePhoto());

  Future<void> choosePhoto() => _addPhoto(_capture.choosePhoto());

  Future<void> _addPhoto(Future<Uint8List?> capture) async {
    final bytes = await capture;
    if (bytes == null) return;

    _photos.add(DraftPhoto.captured(bytes));
    notifyListeners();
  }

  void removePhotoAt(int index) {
    if (index < 0 || index >= _photos.length) return;
    _photos.removeAt(index);
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (_isRecording) return;

    final started = await _capture.startRecording();
    if (!started) {
      _microphoneUnavailable = true;
      notifyListeners();
      return;
    }

    _microphoneUnavailable = false;
    _isRecording = true;
    _recordingStartedAt = DateTime.now();
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (!_isRecording) return;

    final elapsed = recordingElapsed;
    final bytes = await _capture.stopRecording();

    _isRecording = false;
    _recordingStartedAt = null;

    if (bytes != null) {
      _voiceBytes = bytes;
      // Replacing a stored recording: the old blob is pruned on save.
      _voiceReference = null;
      _voiceDuration = elapsed;
    }

    notifyListeners();
  }

  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    await _capture.cancelRecording();
    _isRecording = false;
    _recordingStartedAt = null;
    notifyListeners();
  }

  void removeVoiceNote() {
    _voiceBytes = null;
    _voiceReference = null;
    _voiceDuration = null;
    notifyListeners();
  }

  /// Writes any captured media, then returns the job to persist.
  ///
  /// Returns null when the draft has nothing to show — the caller keeps the
  /// user on the form rather than saving an empty job.
  Future<Job?> build() async {
    if (!hasContent) {
      _errorMessage = 'Add a voice note, photo, or short message first.';
      notifyListeners();
      return null;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final photoReferences = <String>[];
      for (final photo in _photos) {
        if (photo.isNew) {
          photoReferences.add(
            await _mediaStore.save(photo.bytes!, extension: 'jpg'),
          );
        } else {
          photoReferences.add(photo.reference!);
        }
      }

      var voiceReference = _voiceReference;
      if (_voiceBytes != null) {
        voiceReference = await _mediaStore.save(_voiceBytes!, extension: 'm4a');
      }

      final trimmedTitle = _title.trim();
      final trimmedDescription = _description.trim();
      final trimmedContact = _contactNumber.trim();

      return Job(
        id: _editing?.id ?? _uuid.v4(),
        location: _location,
        createdAt: _editing?.createdAt ?? DateTime.now(),
        title: trimmedTitle.isEmpty ? null : trimmedTitle,
        type: _type,
        radiusMetres: _radiusMetres,
        scheduledTime: _scheduledTime,
        voiceNotePath: voiceReference,
        voiceNoteDuration: _voiceDuration,
        photoPaths: photoReferences,
        shortDescription: trimmedDescription.isEmpty
            ? null
            : trimmedDescription,
        contactNumber: trimmedContact.isEmpty ? null : trimmedContact,
        postedBy: _editing?.postedBy,
        // Anything written here lives on this device only.
        isLocal: true,
      );
    } catch (error) {
      if (kDebugMode) debugPrint('Saving the draft failed: $error');
      _errorMessage = 'Could not save your job. Try again.';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isRecording) _capture.cancelRecording();
    super.dispose();
  }
}
