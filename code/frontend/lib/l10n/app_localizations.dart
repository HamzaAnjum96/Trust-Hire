import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppStrings
/// returned by `AppStrings.of(context)`.
///
/// Applications need to include `AppStrings.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppStrings.localizationsDelegates,
///   supportedLocales: AppStrings.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppStrings.supportedLocales
/// property.
abstract class AppStrings {
  AppStrings(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  static const LocalizationsDelegate<AppStrings> delegate =
      _AppStringsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ur'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Trust Hire'**
  String get appTitle;

  /// No description provided for @languageName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageName;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get navJobs;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @postAJob.
  ///
  /// In en, this message translates to:
  /// **'Post a Job'**
  String get postAJob;

  /// No description provided for @nearbyWork.
  ///
  /// In en, this message translates to:
  /// **'Nearby work'**
  String get nearbyWork;

  /// No description provided for @findWork.
  ///
  /// In en, this message translates to:
  /// **'Find work'**
  String get findWork;

  /// No description provided for @jobCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job} other{{count} jobs}}'**
  String jobCount(int count);

  /// No description provided for @jobCountFiltered.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String jobCountFiltered(int shown, int total);

  /// No description provided for @loadingJobs.
  ///
  /// In en, this message translates to:
  /// **'Loading nearby jobs…'**
  String get loadingJobs;

  /// No description provided for @couldNotLoadJobs.
  ///
  /// In en, this message translates to:
  /// **'Could not load jobs. Pull down to try again.'**
  String get couldNotLoadJobs;

  /// No description provided for @couldNotLoadJobsShort.
  ///
  /// In en, this message translates to:
  /// **'Could not load jobs. Try again.'**
  String get couldNotLoadJobsShort;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @showAllJobs.
  ///
  /// In en, this message translates to:
  /// **'Show all jobs'**
  String get showAllJobs;

  /// No description provided for @nearMeLabel.
  ///
  /// In en, this message translates to:
  /// **'Near me'**
  String get nearMeLabel;

  /// No description provided for @clusterLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} jobs here. Tap to zoom in.'**
  String clusterLabel(int count);

  /// No description provided for @mapLabel.
  ///
  /// In en, this message translates to:
  /// **'Map of nearby jobs'**
  String get mapLabel;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get yourLocation;

  /// No description provided for @mapImagesNotLoading.
  ///
  /// In en, this message translates to:
  /// **'Map images are not loading. Jobs are still shown in the right places.'**
  String get mapImagesNotLoading;

  /// No description provided for @noJobsMatchHere.
  ///
  /// In en, this message translates to:
  /// **'No jobs match here. Try a wider area or a different time.'**
  String get noJobsMatchHere;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'Location access is off. You can still move the map and choose an area manually.'**
  String get locationOff;

  /// No description provided for @locationOffForApp.
  ///
  /// In en, this message translates to:
  /// **'Location access is off for this app. You can still move the map and choose an area manually.'**
  String get locationOffForApp;

  /// No description provided for @locationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location is switched off on this device. You can still move the map and choose an area manually.'**
  String get locationServiceOff;

  /// No description provided for @locationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not find your location. You can still move the map and choose an area manually.'**
  String get locationNotFound;

  /// No description provided for @searchJobs.
  ///
  /// In en, this message translates to:
  /// **'Search jobs'**
  String get searchJobs;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @todaysJobs.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Jobs'**
  String get todaysJobs;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @anyTime.
  ///
  /// In en, this message translates to:
  /// **'Any time'**
  String get anyTime;

  /// No description provided for @nearMe.
  ///
  /// In en, this message translates to:
  /// **'Near Me'**
  String get nearMe;

  /// No description provided for @anyDistance.
  ///
  /// In en, this message translates to:
  /// **'Any distance'**
  String get anyDistance;

  /// No description provided for @withinFive.
  ///
  /// In en, this message translates to:
  /// **'Within 5 km'**
  String get withinFive;

  /// No description provided for @withinTen.
  ///
  /// In en, this message translates to:
  /// **'Within 10 km'**
  String get withinTen;

  /// No description provided for @voiceNote.
  ///
  /// In en, this message translates to:
  /// **'Voice note'**
  String get voiceNote;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @showJobs.
  ///
  /// In en, this message translates to:
  /// **'Show Jobs'**
  String get showJobs;

  /// No description provided for @filterWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get filterWhen;

  /// No description provided for @filterHowFar.
  ///
  /// In en, this message translates to:
  /// **'How far'**
  String get filterHowFar;

  /// No description provided for @filterIncludes.
  ///
  /// In en, this message translates to:
  /// **'What it includes'**
  String get filterIncludes;

  /// No description provided for @filterKind.
  ///
  /// In en, this message translates to:
  /// **'Kind of work'**
  String get filterKind;

  /// No description provided for @filterKindWarning.
  ///
  /// In en, this message translates to:
  /// **'Jobs that did not say what kind they are will be hidden.'**
  String get filterKindWarning;

  /// No description provided for @noJobsYet.
  ///
  /// In en, this message translates to:
  /// **'No jobs yet'**
  String get noJobsYet;

  /// No description provided for @postTheFirstJob.
  ///
  /// In en, this message translates to:
  /// **'Post the first job to see it here.'**
  String get postTheFirstJob;

  /// No description provided for @noJobsMatch.
  ///
  /// In en, this message translates to:
  /// **'No jobs match'**
  String get noJobsMatch;

  /// No description provided for @tryWiderArea.
  ///
  /// In en, this message translates to:
  /// **'Try a wider area or a different time.'**
  String get tryWiderArea;

  /// No description provided for @postedAgo.
  ///
  /// In en, this message translates to:
  /// **'Posted {when}'**
  String postedAgo(String when);

  /// No description provided for @onThisDevice.
  ///
  /// In en, this message translates to:
  /// **'On this device'**
  String get onThisDevice;

  /// No description provided for @detailWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get detailWhen;

  /// No description provided for @detailArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get detailArea;

  /// No description provided for @detailPostedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by'**
  String get detailPostedBy;

  /// No description provided for @detailKindOfWork.
  ///
  /// In en, this message translates to:
  /// **'Kind of work'**
  String get detailKindOfWork;

  /// No description provided for @generalAreaNotice.
  ///
  /// In en, this message translates to:
  /// **'This is the general area, not an exact address.'**
  String get generalAreaNotice;

  /// No description provided for @jobNoLongerHere.
  ///
  /// In en, this message translates to:
  /// **'This job is no longer here.'**
  String get jobNoLongerHere;

  /// No description provided for @photoOfCount.
  ///
  /// In en, this message translates to:
  /// **'Photo {index} of {total}'**
  String photoOfCount(int index, int total);

  /// No description provided for @photoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String photoCount(int count);

  /// No description provided for @listen.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listen;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get playing;

  /// No description provided for @voiceNoteCouldNotPlay.
  ///
  /// In en, this message translates to:
  /// **'This voice note could not be played.'**
  String get voiceNoteCouldNotPlay;

  /// No description provided for @postAJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Post a job'**
  String get postAJobTitle;

  /// No description provided for @editJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit job'**
  String get editJobTitle;

  /// No description provided for @whatWorkDoYouNeed.
  ///
  /// In en, this message translates to:
  /// **'What work do you need?'**
  String get whatWorkDoYouNeed;

  /// No description provided for @anyOneIsEnough.
  ///
  /// In en, this message translates to:
  /// **'Add a voice note, photo, or short message. Any one is enough.'**
  String get anyOneIsEnough;

  /// No description provided for @tellPeopleAboutTheJob.
  ///
  /// In en, this message translates to:
  /// **'Tell people about the job'**
  String get tellPeopleAboutTheJob;

  /// No description provided for @speakNaturally.
  ///
  /// In en, this message translates to:
  /// **'Speak naturally. You do not need to prepare anything.'**
  String get speakNaturally;

  /// No description provided for @recordAVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Record a voice note'**
  String get recordAVoiceNote;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording…'**
  String get recording;

  /// No description provided for @stopRecording.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopRecording;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @voiceNoteAdded.
  ///
  /// In en, this message translates to:
  /// **'Voice Note Added'**
  String get voiceNoteAdded;

  /// No description provided for @recordAgain.
  ///
  /// In en, this message translates to:
  /// **'Record Again'**
  String get recordAgain;

  /// No description provided for @removeVoiceNote.
  ///
  /// In en, this message translates to:
  /// **'Remove voice note'**
  String get removeVoiceNote;

  /// No description provided for @microphoneOff.
  ///
  /// In en, this message translates to:
  /// **'Microphone access is off. You can still add a photo or type a short message.'**
  String get microphoneOff;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get choosePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @kindOfWorkOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional. Choosing one makes your job easier to spot on the map.'**
  String get kindOfWorkOptional;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'Short title. You can add this later.'**
  String get titleHint;

  /// No description provided for @fieldMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get fieldMessage;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Anything else worth knowing.'**
  String get messageHint;

  /// No description provided for @fieldArea.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get fieldArea;

  /// No description provided for @areaHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose the general area. Your exact location will not be shown.'**
  String get areaHelp;

  /// No description provided for @moveMapToChooseArea.
  ///
  /// In en, this message translates to:
  /// **'Move the map to choose the area'**
  String get moveMapToChooseArea;

  /// No description provided for @clearTime.
  ///
  /// In en, this message translates to:
  /// **'Clear time'**
  String get clearTime;

  /// No description provided for @whenIsWorkNeeded.
  ///
  /// In en, this message translates to:
  /// **'When is the work needed?'**
  String get whenIsWorkNeeded;

  /// No description provided for @whatTime.
  ///
  /// In en, this message translates to:
  /// **'What time?'**
  String get whatTime;

  /// No description provided for @addAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Add at least one voice note, photo, or message.'**
  String get addAtLeastOne;

  /// No description provided for @addSomethingFirst.
  ///
  /// In en, this message translates to:
  /// **'Add a voice note, photo, or short message first.'**
  String get addSomethingFirst;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save your job. Try again.'**
  String get couldNotSave;

  /// No description provided for @saveJob.
  ///
  /// In en, this message translates to:
  /// **'Save Job'**
  String get saveJob;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @postedOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Your job has been posted on this device.'**
  String get postedOnThisDevice;

  /// No description provided for @changesSaved.
  ///
  /// In en, this message translates to:
  /// **'Your changes have been saved on this device.'**
  String get changesSaved;

  /// No description provided for @editJob.
  ///
  /// In en, this message translates to:
  /// **'Edit Job'**
  String get editJob;

  /// No description provided for @deleteJob.
  ///
  /// In en, this message translates to:
  /// **'Delete Job'**
  String get deleteJob;

  /// No description provided for @deleteThisJob.
  ///
  /// In en, this message translates to:
  /// **'Delete this job?'**
  String get deleteThisJob;

  /// No description provided for @deleteJobExplanation.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from this device. This cannot be undone.'**
  String get deleteJobExplanation;

  /// No description provided for @keepJob.
  ///
  /// In en, this message translates to:
  /// **'Keep Job'**
  String get keepJob;

  /// No description provided for @jobDeleted.
  ///
  /// In en, this message translates to:
  /// **'Job deleted from this device.'**
  String get jobDeleted;

  /// No description provided for @settingsStorageNotice.
  ///
  /// In en, this message translates to:
  /// **'This POC stores jobs only on this device. Nothing is uploaded and no account is needed.'**
  String get settingsStorageNotice;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @localData.
  ///
  /// In en, this message translates to:
  /// **'Local data'**
  String get localData;

  /// No description provided for @restoreSeedExplanation.
  ///
  /// In en, this message translates to:
  /// **'Restoring the seed data removes every job you created on this device and brings back the original examples.'**
  String get restoreSeedExplanation;

  /// No description provided for @restoreSeedData.
  ///
  /// In en, this message translates to:
  /// **'Restore Seed Data'**
  String get restoreSeedData;

  /// No description provided for @restoreSeedTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore seed data?'**
  String get restoreSeedTitle;

  /// No description provided for @restoreSeedWarning.
  ///
  /// In en, this message translates to:
  /// **'Jobs you created on this device will be removed. This cannot be undone.'**
  String get restoreSeedWarning;

  /// No description provided for @keepMyJobs.
  ///
  /// In en, this message translates to:
  /// **'Keep My Jobs'**
  String get keepMyJobs;

  /// No description provided for @seedRestored.
  ///
  /// In en, this message translates to:
  /// **'Seed data restored.'**
  String get seedRestored;

  /// No description provided for @typePlumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get typePlumbing;

  /// No description provided for @typeElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get typeElectrical;

  /// No description provided for @typePainting.
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get typePainting;

  /// No description provided for @typeCarpentry.
  ///
  /// In en, this message translates to:
  /// **'Carpentry'**
  String get typeCarpentry;

  /// No description provided for @typeMasonry.
  ///
  /// In en, this message translates to:
  /// **'Masonry'**
  String get typeMasonry;

  /// No description provided for @typeConstruction.
  ///
  /// In en, this message translates to:
  /// **'Construction'**
  String get typeConstruction;

  /// No description provided for @typeApplianceRepair.
  ///
  /// In en, this message translates to:
  /// **'Appliance repair'**
  String get typeApplianceRepair;

  /// No description provided for @typeCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get typeCleaning;

  /// No description provided for @typeMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving'**
  String get typeMoving;

  /// No description provided for @typeDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get typeDriving;

  /// No description provided for @typeGardening.
  ///
  /// In en, this message translates to:
  /// **'Gardening'**
  String get typeGardening;

  /// No description provided for @typeTailoring.
  ///
  /// In en, this message translates to:
  /// **'Tailoring'**
  String get typeTailoring;

  /// No description provided for @typeCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get typeCooking;

  /// No description provided for @typeTutoring.
  ///
  /// In en, this message translates to:
  /// **'Tutoring'**
  String get typeTutoring;

  /// No description provided for @typeSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get typeSecurity;

  /// No description provided for @typeOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get typeOther;

  /// No description provided for @voiceNoteJob.
  ///
  /// In en, this message translates to:
  /// **'Voice note job'**
  String get voiceNoteJob;

  /// No description provided for @photoJob.
  ///
  /// In en, this message translates to:
  /// **'Photo job'**
  String get photoJob;

  /// No description provided for @untitledJob.
  ///
  /// In en, this message translates to:
  /// **'Untitled job'**
  String get untitledJob;

  /// No description provided for @veryClose.
  ///
  /// In en, this message translates to:
  /// **'Very close'**
  String get veryClose;

  /// No description provided for @metresAway.
  ///
  /// In en, this message translates to:
  /// **'{metres} m away'**
  String metresAway(int metres);

  /// No description provided for @kilometresAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String kilometresAway(String km);

  /// No description provided for @metresArea.
  ///
  /// In en, this message translates to:
  /// **'{metres} m area'**
  String metresArea(int metres);

  /// No description provided for @kilometresArea.
  ///
  /// In en, this message translates to:
  /// **'{km} km area'**
  String kilometresArea(String km);

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String todayAt(String time);

  /// No description provided for @tomorrowAt.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, {time}'**
  String tomorrowAt(String time);

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {time}'**
  String yesterdayAt(String time);

  /// No description provided for @dayAt.
  ///
  /// In en, this message translates to:
  /// **'{day}, {time}'**
  String dayAt(String day, String time);

  /// No description provided for @wasOn.
  ///
  /// In en, this message translates to:
  /// **'Was {date}'**
  String wasOn(String date);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String daysAgo(int count);
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  Future<AppStrings> load(Locale locale) {
    return SynchronousFuture<AppStrings>(lookupAppStrings(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppStringsDelegate old) => false;
}

AppStrings lookupAppStrings(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppStringsEn();
    case 'ur':
      return AppStringsUr();
  }

  throw FlutterError(
    'AppStrings.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
