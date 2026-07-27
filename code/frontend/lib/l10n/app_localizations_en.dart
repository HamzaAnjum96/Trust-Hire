// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppStringsEn extends AppStrings {
  AppStringsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Trust Hire';

  @override
  String get languageName => 'English';

  @override
  String get navMap => 'Map';

  @override
  String get navJobs => 'Jobs';

  @override
  String get navSettings => 'Settings';

  @override
  String get postAJob => 'Post a Job';

  @override
  String get nearbyWork => 'Nearby work';

  @override
  String get findWork => 'Find work';

  @override
  String jobCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs',
      one: '1 job',
    );
    return '$_temp0';
  }

  @override
  String jobCountFiltered(int shown, int total) {
    return '$shown of $total';
  }

  @override
  String get loadingJobs => 'Loading nearby jobs…';

  @override
  String get couldNotLoadJobs => 'Could not load jobs. Pull down to try again.';

  @override
  String get couldNotLoadJobsShort => 'Could not load jobs. Try again.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get close => 'Close';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get showAllJobs => 'Show all jobs';

  @override
  String get nearMeLabel => 'Near me';

  @override
  String clusterLabel(int count) {
    return '$count jobs here. Tap to zoom in.';
  }

  @override
  String get mapLabel => 'Map of nearby jobs';

  @override
  String get yourLocation => 'Your location';

  @override
  String get mapImagesNotLoading =>
      'Map images are not loading. Jobs are still shown in the right places.';

  @override
  String get noJobsMatchHere =>
      'No jobs match here. Try a wider area or a different time.';

  @override
  String get locationOff =>
      'Location access is off. You can still move the map and choose an area manually.';

  @override
  String get locationOffForApp =>
      'Location access is off for this app. You can still move the map and choose an area manually.';

  @override
  String get locationServiceOff =>
      'Location is switched off on this device. You can still move the map and choose an area manually.';

  @override
  String get locationNotFound =>
      'Could not find your location. You can still move the map and choose an area manually.';

  @override
  String get searchJobs => 'Search jobs';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get todaysJobs => 'Today\'s Jobs';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get thisWeek => 'This week';

  @override
  String get anyTime => 'Any time';

  @override
  String get nearMe => 'Near Me';

  @override
  String get anyDistance => 'Any distance';

  @override
  String get withinFive => 'Within 5 km';

  @override
  String get withinTen => 'Within 10 km';

  @override
  String get voiceNote => 'Voice note';

  @override
  String get photos => 'Photos';

  @override
  String get more => 'More';

  @override
  String get clear => 'Clear';

  @override
  String get clearAll => 'Clear All';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get showJobs => 'Show Jobs';

  @override
  String get filterWhen => 'When';

  @override
  String get filterHowFar => 'How far';

  @override
  String get filterIncludes => 'What it includes';

  @override
  String get filterKind => 'Kind of work';

  @override
  String get filterKindWarning =>
      'Jobs that did not say what kind they are will be hidden.';

  @override
  String get noJobsYet => 'No jobs yet';

  @override
  String get postTheFirstJob => 'Post the first job to see it here.';

  @override
  String get noJobsMatch => 'No jobs match';

  @override
  String get tryWiderArea => 'Try a wider area or a different time.';

  @override
  String postedAgo(String when) {
    return 'Posted $when';
  }

  @override
  String get onThisDevice => 'On this device';

  @override
  String get detailWhen => 'When';

  @override
  String get detailArea => 'Area';

  @override
  String get detailPostedBy => 'Posted by';

  @override
  String get detailKindOfWork => 'Kind of work';

  @override
  String get generalAreaNotice =>
      'This is the general area, not an exact address.';

  @override
  String get jobNoLongerHere => 'This job is no longer here.';

  @override
  String photoOfCount(int index, int total) {
    return 'Photo $index of $total';
  }

  @override
  String photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get listen => 'Listen';

  @override
  String get pause => 'Pause';

  @override
  String get playing => 'Playing';

  @override
  String get voiceNoteCouldNotPlay => 'This voice note could not be played.';

  @override
  String get postAJobTitle => 'Post a job';

  @override
  String get editJobTitle => 'Edit job';

  @override
  String get whatWorkDoYouNeed => 'What work do you need?';

  @override
  String get anyOneIsEnough =>
      'Add a voice note, photo, or short message. Any one is enough.';

  @override
  String get tellPeopleAboutTheJob => 'Tell people about the job';

  @override
  String get speakNaturally =>
      'Speak naturally. You do not need to prepare anything.';

  @override
  String get recordAVoiceNote => 'Record a voice note';

  @override
  String get recording => 'Recording…';

  @override
  String get stopRecording => 'Stop recording';

  @override
  String get discard => 'Discard';

  @override
  String get voiceNoteAdded => 'Voice Note Added';

  @override
  String get recordAgain => 'Record Again';

  @override
  String get removeVoiceNote => 'Remove voice note';

  @override
  String get microphoneOff =>
      'Microphone access is off. You can still add a photo or type a short message.';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get choosePhoto => 'Choose Photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get kindOfWorkOptional =>
      'Optional. Choosing one makes your job easier to spot on the map.';

  @override
  String get fieldTitle => 'Title';

  @override
  String get titleHint => 'Short title. You can add this later.';

  @override
  String get fieldMessage => 'Message';

  @override
  String get messageHint => 'Anything else worth knowing.';

  @override
  String get fieldArea => 'Area';

  @override
  String get areaHelp =>
      'Choose the general area. Your exact location will not be shown.';

  @override
  String get moveMapToChooseArea => 'Move the map to choose the area';

  @override
  String get clearTime => 'Clear time';

  @override
  String get whenIsWorkNeeded => 'When is the work needed?';

  @override
  String get whatTime => 'What time?';

  @override
  String get addAtLeastOne => 'Add at least one voice note, photo, or message.';

  @override
  String get addSomethingFirst =>
      'Add a voice note, photo, or short message first.';

  @override
  String get couldNotSave => 'Could not save your job. Try again.';

  @override
  String get saveJob => 'Save Job';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get postedOnThisDevice => 'Your job has been posted on this device.';

  @override
  String get changesSaved => 'Your changes have been saved on this device.';

  @override
  String get editJob => 'Edit Job';

  @override
  String get deleteJob => 'Delete Job';

  @override
  String get deleteThisJob => 'Delete this job?';

  @override
  String get deleteJobExplanation =>
      'It will be removed from this device. This cannot be undone.';

  @override
  String get keepJob => 'Keep Job';

  @override
  String get jobDeleted => 'Job deleted from this device.';

  @override
  String get settingsStorageNotice =>
      'This POC stores jobs only on this device. Nothing is uploaded and no account is needed.';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get localData => 'Local data';

  @override
  String get restoreSeedExplanation =>
      'Restoring the seed data removes every job you created on this device and brings back the original examples.';

  @override
  String get restoreSeedData => 'Restore Seed Data';

  @override
  String get restoreSeedTitle => 'Restore seed data?';

  @override
  String get restoreSeedWarning =>
      'Jobs you created on this device will be removed. This cannot be undone.';

  @override
  String get keepMyJobs => 'Keep My Jobs';

  @override
  String get seedRestored => 'Seed data restored.';

  @override
  String get typePlumbing => 'Plumbing';

  @override
  String get typeElectrical => 'Electrical';

  @override
  String get typePainting => 'Painting';

  @override
  String get typeCarpentry => 'Carpentry';

  @override
  String get typeMasonry => 'Masonry';

  @override
  String get typeConstruction => 'Construction';

  @override
  String get typeApplianceRepair => 'Appliance repair';

  @override
  String get typeCleaning => 'Cleaning';

  @override
  String get typeMoving => 'Moving';

  @override
  String get typeDriving => 'Driving';

  @override
  String get typeGardening => 'Gardening';

  @override
  String get typeTailoring => 'Tailoring';

  @override
  String get typeCooking => 'Cooking';

  @override
  String get typeTutoring => 'Tutoring';

  @override
  String get typeSecurity => 'Security';

  @override
  String get typeOther => 'Something else';

  @override
  String get voiceNoteJob => 'Voice note job';

  @override
  String get photoJob => 'Photo job';

  @override
  String get untitledJob => 'Untitled job';

  @override
  String get veryClose => 'Very close';

  @override
  String metresAway(int metres) {
    return '$metres m away';
  }

  @override
  String kilometresAway(String km) {
    return '$km km away';
  }

  @override
  String metresArea(int metres) {
    return '$metres m area';
  }

  @override
  String kilometresArea(String km) {
    return '$km km area';
  }

  @override
  String todayAt(String time) {
    return 'Today, $time';
  }

  @override
  String tomorrowAt(String time) {
    return 'Tomorrow, $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Yesterday, $time';
  }

  @override
  String dayAt(String day, String time) {
    return '$day, $time';
  }

  @override
  String wasOn(String date) {
    return 'Was $date';
  }

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get contact => 'Contact';

  @override
  String get contactShow => 'Show Contact';

  @override
  String get contactHiddenNotice =>
      'Contact details are shown only when you ask for them.';

  @override
  String get callNumber => 'Call';

  @override
  String get whatsAppNumber => 'WhatsApp';

  @override
  String get copyNumber => 'Copy Number';

  @override
  String get numberCopied => 'Number copied.';

  @override
  String get couldNotOpenDialer =>
      'Could not open the phone app. The number is above, so you can dial it yourself.';

  @override
  String get couldNotOpenWhatsApp =>
      'Could not open WhatsApp. The number is above, so you can message it yourself.';

  @override
  String get noContactGiven => 'This job has no contact details.';

  @override
  String get fieldContact => 'Phone number';

  @override
  String get contactHint => 'So people can reach you. You can add this later.';

  @override
  String get contactHelp => 'Shown only to people who tap to see it.';

  @override
  String get whatsAppMessage => 'Salaam, I saw your job on Trust Hire.';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get saveThisJob => 'Save this job';

  @override
  String get removeFromSaved => 'Remove from saved';

  @override
  String get jobSaved => 'Saved. Find it under Saved.';

  @override
  String get jobUnsaved => 'Removed from saved.';

  @override
  String get navSaved => 'Saved';

  @override
  String get savedJobs => 'Saved jobs';

  @override
  String get myPostings => 'My postings';

  @override
  String get noSavedJobs => 'Nothing saved yet';

  @override
  String get noSavedJobsMessage => 'Tap the bookmark on a job to keep it here.';

  @override
  String get noPostings => 'You have not posted any work yet';

  @override
  String get noPostingsMessage => 'Anything you post shows up here.';

  @override
  String get savedTab => 'Saved';

  @override
  String get postedTab => 'Posted';

  @override
  String savedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved',
      one: '1 saved',
    );
    return '$_temp0';
  }

  @override
  String postedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count posted',
      one: '1 posted',
    );
    return '$_temp0';
  }

  @override
  String get savedJobGone => 'A job you saved is no longer here.';

  @override
  String get onboardWelcomeTitle => 'Nearby work, made simple';

  @override
  String get onboardWelcomeBody =>
      'Trust Hire shows work happening near you, on a map. No account, nothing to fill in.';

  @override
  String get onboardVoiceTitle => 'Say it, do not type it';

  @override
  String get onboardVoiceBody =>
      'Post a job with a voice note, a photo, or a few words. Any one of them is enough — you never have to fill in a form.';

  @override
  String get onboardLocationTitle => 'Work near you';

  @override
  String get onboardLocationBody =>
      'If you share your location, jobs are sorted by how close they are. You can say no and still use everything — just move the map yourself.';

  @override
  String get onboardPrivacyNote =>
      'Your exact location is never shown on a job. Only a general area is.';

  @override
  String get onboardNext => 'Next';

  @override
  String get onboardSkip => 'Skip';

  @override
  String get onboardAllowLocation => 'Share My Location';

  @override
  String get onboardNotNow => 'Not Now';

  @override
  String get onboardStart => 'Start';

  @override
  String onboardStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get showIntroAgain => 'Show Intro Again';

  @override
  String get introReset => 'The intro will show next time you open the app.';
}
