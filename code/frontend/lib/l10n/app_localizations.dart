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
  /// **'This is the general area. The exact spot is shared once a worker is chosen.'**
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
  /// **'Choose the general area. Only this area is shown until you choose someone — then they get the exact spot.'**
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

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @contactShow.
  ///
  /// In en, this message translates to:
  /// **'Show Contact'**
  String get contactShow;

  /// No description provided for @contactHiddenNotice.
  ///
  /// In en, this message translates to:
  /// **'Contact details are shown only when you ask for them.'**
  String get contactHiddenNotice;

  /// No description provided for @callNumber.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callNumber;

  /// No description provided for @whatsAppNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsAppNumber;

  /// No description provided for @copyNumber.
  ///
  /// In en, this message translates to:
  /// **'Copy Number'**
  String get copyNumber;

  /// No description provided for @numberCopied.
  ///
  /// In en, this message translates to:
  /// **'Number copied.'**
  String get numberCopied;

  /// No description provided for @couldNotOpenDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not open the phone app. The number is above, so you can dial it yourself.'**
  String get couldNotOpenDialer;

  /// No description provided for @couldNotOpenWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Could not open WhatsApp. The number is above, so you can message it yourself.'**
  String get couldNotOpenWhatsApp;

  /// No description provided for @noContactGiven.
  ///
  /// In en, this message translates to:
  /// **'This job has no contact details.'**
  String get noContactGiven;

  /// No description provided for @fieldContact.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get fieldContact;

  /// No description provided for @contactHint.
  ///
  /// In en, this message translates to:
  /// **'So people can reach you. You can add this later.'**
  String get contactHint;

  /// No description provided for @contactHelp.
  ///
  /// In en, this message translates to:
  /// **'Shown only to people who tap to see it.'**
  String get contactHelp;

  /// No description provided for @whatsAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Salaam, I saw your job on Trust Hire.'**
  String get whatsAppMessage;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @saveThisJob.
  ///
  /// In en, this message translates to:
  /// **'Save this job'**
  String get saveThisJob;

  /// No description provided for @removeFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get removeFromSaved;

  /// No description provided for @jobSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved. Find it under Saved.'**
  String get jobSaved;

  /// No description provided for @jobUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved.'**
  String get jobUnsaved;

  /// No description provided for @savedJobs.
  ///
  /// In en, this message translates to:
  /// **'Saved jobs'**
  String get savedJobs;

  /// No description provided for @myPostings.
  ///
  /// In en, this message translates to:
  /// **'My postings'**
  String get myPostings;

  /// No description provided for @noSavedJobs.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get noSavedJobs;

  /// No description provided for @noSavedJobsMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on a job to keep it here.'**
  String get noSavedJobsMessage;

  /// No description provided for @noPostings.
  ///
  /// In en, this message translates to:
  /// **'You have not posted any work yet'**
  String get noPostings;

  /// No description provided for @noPostingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Anything you post shows up here.'**
  String get noPostingsMessage;

  /// No description provided for @savedTab.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTab;

  /// No description provided for @postedTab.
  ///
  /// In en, this message translates to:
  /// **'Posted'**
  String get postedTab;

  /// No description provided for @savedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved} other{{count} saved}}'**
  String savedCount(int count);

  /// No description provided for @postedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 posted} other{{count} posted}}'**
  String postedCount(int count);

  /// No description provided for @savedJobGone.
  ///
  /// In en, this message translates to:
  /// **'A job you saved is no longer here.'**
  String get savedJobGone;

  /// No description provided for @onboardWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby work, made simple'**
  String get onboardWelcomeTitle;

  /// No description provided for @onboardWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Trust Hire shows work happening near you, on a map. No account, nothing to fill in.'**
  String get onboardWelcomeBody;

  /// No description provided for @onboardVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Say it, do not type it'**
  String get onboardVoiceTitle;

  /// No description provided for @onboardVoiceBody.
  ///
  /// In en, this message translates to:
  /// **'Post a job with a voice note, a photo, or a few words. Any one of them is enough — you never have to fill in a form.'**
  String get onboardVoiceBody;

  /// No description provided for @onboardLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Work near you'**
  String get onboardLocationTitle;

  /// No description provided for @onboardLocationBody.
  ///
  /// In en, this message translates to:
  /// **'If you share your location, jobs are sorted by how close they are. You can say no and still use everything — just move the map yourself.'**
  String get onboardLocationBody;

  /// No description provided for @onboardPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your exact location stays hidden while people are offering. It is shared only with the person you choose.'**
  String get onboardPrivacyNote;

  /// No description provided for @onboardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardNext;

  /// No description provided for @onboardSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardSkip;

  /// No description provided for @onboardAllowLocation.
  ///
  /// In en, this message translates to:
  /// **'Share My Location'**
  String get onboardAllowLocation;

  /// No description provided for @onboardNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not Now'**
  String get onboardNotNow;

  /// No description provided for @onboardStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get onboardStart;

  /// No description provided for @onboardStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String onboardStepOf(int step, int total);

  /// No description provided for @showIntroAgain.
  ///
  /// In en, this message translates to:
  /// **'Show Intro Again'**
  String get showIntroAgain;

  /// No description provided for @introReset.
  ///
  /// In en, this message translates to:
  /// **'The intro will show next time you open the app.'**
  String get introReset;

  /// No description provided for @tagPlumbing.
  ///
  /// In en, this message translates to:
  /// **'Plumbing'**
  String get tagPlumbing;

  /// No description provided for @tagElectrical.
  ///
  /// In en, this message translates to:
  /// **'Electrical'**
  String get tagElectrical;

  /// No description provided for @tagPainting.
  ///
  /// In en, this message translates to:
  /// **'Painting'**
  String get tagPainting;

  /// No description provided for @tagCarpentry.
  ///
  /// In en, this message translates to:
  /// **'Carpentry'**
  String get tagCarpentry;

  /// No description provided for @tagMasonry.
  ///
  /// In en, this message translates to:
  /// **'Masonry'**
  String get tagMasonry;

  /// No description provided for @tagConstruction.
  ///
  /// In en, this message translates to:
  /// **'Construction'**
  String get tagConstruction;

  /// No description provided for @tagApplianceRepair.
  ///
  /// In en, this message translates to:
  /// **'Appliance repair'**
  String get tagApplianceRepair;

  /// No description provided for @tagCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get tagCleaning;

  /// No description provided for @tagMoving.
  ///
  /// In en, this message translates to:
  /// **'Moving'**
  String get tagMoving;

  /// No description provided for @tagDriving.
  ///
  /// In en, this message translates to:
  /// **'Driving'**
  String get tagDriving;

  /// No description provided for @tagGardening.
  ///
  /// In en, this message translates to:
  /// **'Gardening'**
  String get tagGardening;

  /// No description provided for @tagTailoring.
  ///
  /// In en, this message translates to:
  /// **'Tailoring'**
  String get tagTailoring;

  /// No description provided for @tagCooking.
  ///
  /// In en, this message translates to:
  /// **'Cooking'**
  String get tagCooking;

  /// No description provided for @tagTutoring.
  ///
  /// In en, this message translates to:
  /// **'Tutoring'**
  String get tagTutoring;

  /// No description provided for @tagSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get tagSecurity;

  /// No description provided for @tagLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal advice'**
  String get tagLegal;

  /// No description provided for @tagMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get tagMedical;

  /// No description provided for @tagBeauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get tagBeauty;

  /// No description provided for @tagMisc.
  ///
  /// In en, this message translates to:
  /// **'General work'**
  String get tagMisc;

  /// No description provided for @fieldTags.
  ///
  /// In en, this message translates to:
  /// **'Kind of work'**
  String get fieldTags;

  /// No description provided for @tagsHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose 1 to 3. This decides who sees your job.'**
  String get tagsHelp;

  /// No description provided for @tagsRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one kind of work.'**
  String get tagsRequired;

  /// No description provided for @tagsAtMost.
  ///
  /// In en, this message translates to:
  /// **'You can choose up to 3.'**
  String get tagsAtMost;

  /// No description provided for @roleWorker.
  ///
  /// In en, this message translates to:
  /// **'Looking for work'**
  String get roleWorker;

  /// No description provided for @roleHirer.
  ///
  /// In en, this message translates to:
  /// **'Hiring someone'**
  String get roleHirer;

  /// No description provided for @myTrades.
  ///
  /// In en, this message translates to:
  /// **'My trades'**
  String get myTrades;

  /// No description provided for @myTradesHelp.
  ///
  /// In en, this message translates to:
  /// **'You see general work by default. Add your own trade to see those jobs too.'**
  String get myTradesHelp;

  /// Settings section asking whether the user is a worker or a hirer
  ///
  /// In en, this message translates to:
  /// **'What brings you here'**
  String get whatBringsYouHere;

  /// Explains the worker role
  ///
  /// In en, this message translates to:
  /// **'You see jobs near you that match your trades.'**
  String get roleWorkerHelp;

  /// Explains the hirer role
  ///
  /// In en, this message translates to:
  /// **'You post jobs and choose who does them.'**
  String get roleHirerHelp;

  /// Explains why the default trade cannot be switched off
  ///
  /// In en, this message translates to:
  /// **'General work is always on, so you never miss an untagged job.'**
  String get generalWorkAlwaysOn;

  /// No description provided for @tradeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{General work only} =1{General work and 1 trade} other{General work and {count} trades}}'**
  String tradeCount(int count);

  /// Empty feed heading when the visibility rule hid everything
  ///
  /// In en, this message translates to:
  /// **'Nothing here for your trades'**
  String get noJobsForTrades;

  /// Empty feed body when the visibility rule hid everything
  ///
  /// In en, this message translates to:
  /// **'Jobs only reach you when they match a trade you do. Add a trade to see more.'**
  String get noJobsForTradesHelp;

  /// Button opening the trades screen
  ///
  /// In en, this message translates to:
  /// **'Add a trade'**
  String get addATrade;

  /// Bottom navigation label for saved and posted jobs
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// Bottom navigation label for role, trades and settings
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Label on a job whose only description is a voice note
  ///
  /// In en, this message translates to:
  /// **'Described by voice only'**
  String get audioOnlyJob;

  /// Explains an audio-only job to someone who cannot hear it
  ///
  /// In en, this message translates to:
  /// **'There is no written description of this work. Ask the poster if you cannot play the voice note.'**
  String get audioOnlyJobHelp;

  /// Prompt to add text alongside a voice note
  ///
  /// In en, this message translates to:
  /// **'Some people cannot play a voice note. A few words here help them find your job.'**
  String get addWordsForVoiceNote;

  /// Heading over the list beside the map on a wide screen
  ///
  /// In en, this message translates to:
  /// **'Work on this map'**
  String get jobsNearby;

  /// Button on a job row that opens the full details
  ///
  /// In en, this message translates to:
  /// **'Open details'**
  String get openDetails;

  /// Label on the fare field of the posting form
  ///
  /// In en, this message translates to:
  /// **'Starting fare'**
  String get fieldStartingFare;

  /// Explains the starting fare
  ///
  /// In en, this message translates to:
  /// **'Optional. A starting point, not a price — workers will offer their own.'**
  String get startingFareHelp;

  /// Placeholder in a fare field
  ///
  /// In en, this message translates to:
  /// **'Rs. 2,000'**
  String get fareHint;

  /// No description provided for @rupees.
  ///
  /// In en, this message translates to:
  /// **'Rs. {amount}'**
  String rupees(String amount);

  /// No description provided for @startsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at {amount}'**
  String startsAt(String amount);

  /// No description provided for @agreedAt.
  ///
  /// In en, this message translates to:
  /// **'Agreed at {amount}'**
  String agreedAt(String amount);

  /// Button that opens the bidding sheet
  ///
  /// In en, this message translates to:
  /// **'Offer a fare'**
  String get offerAFare;

  /// Button when this device has already bid
  ///
  /// In en, this message translates to:
  /// **'Change my offer'**
  String get changeMyOffer;

  /// No description provided for @yourOffer.
  ///
  /// In en, this message translates to:
  /// **'Your offer: {amount}'**
  String yourOffer(String amount);

  /// Confirms a bid
  ///
  /// In en, this message translates to:
  /// **'Send offer'**
  String get sendOffer;

  /// Removes this worker's bid
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdrawOffer;

  /// Placeholder for the optional bid message
  ///
  /// In en, this message translates to:
  /// **'Anything the hirer should know (optional)'**
  String get offerMessageHint;

  /// Error when a bid is zero or negative
  ///
  /// In en, this message translates to:
  /// **'Enter a fare above zero.'**
  String get fareMustBePositive;

  /// Error when a bid is implausibly high
  ///
  /// In en, this message translates to:
  /// **'That looks like a typo. Check the amount.'**
  String get fareLooksTooHigh;

  /// Heading over the bids on a job
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offersOnThisJob;

  /// No description provided for @offerCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No offers yet} =1{1 offer} other{{count} offers}}'**
  String offerCount(int count);

  /// Empty state under a hirer's job
  ///
  /// In en, this message translates to:
  /// **'Nobody has offered yet. Workers nearby who do this kind of work will see it.'**
  String get noOffersYet;

  /// Button that accepts a bid
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get chooseThisWorker;

  /// Label on the accepted bid
  ///
  /// In en, this message translates to:
  /// **'Chosen'**
  String get chosen;

  /// Label on a bid the hirer passed over
  ///
  /// In en, this message translates to:
  /// **'Not chosen'**
  String get notChosen;

  /// Warns the hirer before accepting
  ///
  /// In en, this message translates to:
  /// **'The fare is fixed once you choose. It cannot be changed afterwards.'**
  String get fareLocked;

  /// No description provided for @confirmChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose this worker at {amount}?'**
  String confirmChoose(String amount);

  /// Why the bid button is absent
  ///
  /// In en, this message translates to:
  /// **'This is your own job.'**
  String get cannotBidOwnJob;

  /// Why bidding is closed
  ///
  /// In en, this message translates to:
  /// **'This job has been given to someone.'**
  String get cannotBidAccepted;

  /// Confirmation after withdrawing a bid
  ///
  /// In en, this message translates to:
  /// **'Your offer was withdrawn.'**
  String get offerWithdrawn;

  /// Dismisses a dialog without acting
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Job status: posted, nobody chosen yet
  ///
  /// In en, this message translates to:
  /// **'Taking offers'**
  String get statusOpen;

  /// Job status: a worker has been picked
  ///
  /// In en, this message translates to:
  /// **'Worker chosen'**
  String get statusAccepted;

  /// Job status: the worker has arrived and started
  ///
  /// In en, this message translates to:
  /// **'Under way'**
  String get statusInProgress;

  /// Job status: the work is done
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get statusCompleted;

  /// Job status: cancelled by either side
  ///
  /// In en, this message translates to:
  /// **'Called off'**
  String get statusCancelled;

  /// Job status: expired without being taken
  ///
  /// In en, this message translates to:
  /// **'No longer listed'**
  String get statusExpired;

  /// Hirer confirms the worker turned up
  ///
  /// In en, this message translates to:
  /// **'They have arrived'**
  String get confirmArrival;

  /// Hirer marks the job done
  ///
  /// In en, this message translates to:
  /// **'Work is finished'**
  String get markComplete;

  /// Cancels a job
  ///
  /// In en, this message translates to:
  /// **'Call this off'**
  String get cancelJob;

  /// Warning before cancelling
  ///
  /// In en, this message translates to:
  /// **'The other person will be told. This cannot be undone.'**
  String get cancelJobExplanation;

  /// Shown on an accepted job's map
  ///
  /// In en, this message translates to:
  /// **'This is the exact spot, shared because you two are working together.'**
  String get exactLocationShown;

  /// Explains the reveal to the hirer
  ///
  /// In en, this message translates to:
  /// **'You chose someone, so you can both see each other\'s exact location now.'**
  String get exactLocationWithWorker;

  /// Notice on a completed job
  ///
  /// In en, this message translates to:
  /// **'This work is finished.'**
  String get jobFinished;

  /// Notice on a cancelled job
  ///
  /// In en, this message translates to:
  /// **'This work was called off.'**
  String get jobCalledOff;

  /// Notice on an expired job
  ///
  /// In en, this message translates to:
  /// **'Nobody was chosen, so this is no longer listed.'**
  String get jobExpired;
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
