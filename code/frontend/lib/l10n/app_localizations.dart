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
  /// **'Your posting'**
  String get onThisDevice;

  /// No description provided for @detailWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get detailWhen;

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

  /// No description provided for @metresPlain.
  ///
  /// In en, this message translates to:
  /// **'{metres} m'**
  String metresPlain(int metres);

  /// No description provided for @kilometresPlain.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String kilometresPlain(String km);

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
  /// **'You offered {fare}'**
  String yourOffer(String fare);

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
  /// **'Withdrawn'**
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

  /// Section heading for the token wallet
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get navWallet;

  /// Label above the token balance
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get walletBalance;

  /// Ledger entry: bought tokens
  ///
  /// In en, this message translates to:
  /// **'Top-up'**
  String get walletTopUp;

  /// Ledger entry: the platform's 5%
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get walletCommission;

  /// Ledger entry: the Rs. 500 starter credit
  ///
  /// In en, this message translates to:
  /// **'First job credit'**
  String get walletFirstJobCredit;

  /// Ledger entry: the 1,000-token bonus
  ///
  /// In en, this message translates to:
  /// **'Loyalty bonus'**
  String get walletLoyaltyBonus;

  /// Ledger entry: the penalty for walking away
  ///
  /// In en, this message translates to:
  /// **'Cancellation charge'**
  String get walletCancellationPenalty;

  /// Explains the wallet
  ///
  /// In en, this message translates to:
  /// **'Trust Hire takes 5% of the agreed fare when a job is finished. Tokens are not real money.'**
  String get walletExplanation;

  /// No description provided for @walletInDebt.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}. You can still take one more job before your account is paused.'**
  String walletInDebt(String amount);

  /// Warning when locked out
  ///
  /// In en, this message translates to:
  /// **'Your account is paused until you clear what you owe. Top up to start getting work again.'**
  String get walletLocked;

  /// Empty ledger
  ///
  /// In en, this message translates to:
  /// **'Nothing has moved yet. Your first job\'s commission will show up here.'**
  String get walletEmpty;

  /// Title of the top-up screen
  ///
  /// In en, this message translates to:
  /// **'Add tokens'**
  String get topUpTitle;

  /// Says the top-up is simulated
  ///
  /// In en, this message translates to:
  /// **'This is a demonstration. No real payment is taken and no card details are asked for.'**
  String get topUpNotReal;

  /// No description provided for @topUpConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add {amount}'**
  String topUpConfirm(String amount);

  /// No description provided for @topUpDone.
  ///
  /// In en, this message translates to:
  /// **'{amount} added to your wallet.'**
  String topUpDone(String amount);

  /// No description provided for @loyaltyProgress.
  ///
  /// In en, this message translates to:
  /// **'{amount} more in top-ups earns a 1,000 token bonus.'**
  String loyaltyProgress(String amount);

  /// No description provided for @firstJobCreditWaiting.
  ///
  /// In en, this message translates to:
  /// **'Your first job\'s commission is covered up to {amount}.'**
  String firstJobCreditWaiting(String amount);

  /// Title of the rating sheet
  ///
  /// In en, this message translates to:
  /// **'How did it go?'**
  String get rateThisJob;

  /// Prompt for a hirer
  ///
  /// In en, this message translates to:
  /// **'Rate the person who did the work'**
  String get rateWorker;

  /// Prompt for a worker
  ///
  /// In en, this message translates to:
  /// **'Rate the person who hired you'**
  String get rateHirer;

  /// Explains that the hirer's rating is internal
  ///
  /// In en, this message translates to:
  /// **'This is not shown to them or to anyone else. It helps us spot people who cause trouble.'**
  String get rateHirerPrivate;

  /// Explains that the worker's rating is public
  ///
  /// In en, this message translates to:
  /// **'This is shown on their profile.'**
  String get rateWorkerPublic;

  /// Placeholder for the optional note
  ///
  /// In en, this message translates to:
  /// **'Anything we should know (optional)'**
  String get rateNoteHint;

  /// Confirms a rating
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendRating;

  /// Confirmation after rating
  ///
  /// In en, this message translates to:
  /// **'Thank you.'**
  String get ratingThanks;

  /// No description provided for @starsChosen.
  ///
  /// In en, this message translates to:
  /// **'{count} of 5'**
  String starsChosen(int count);

  /// Shown once a rating exists
  ///
  /// In en, this message translates to:
  /// **'You have rated this job.'**
  String get alreadyRated;

  /// Heading over a worker's public numbers
  ///
  /// In en, this message translates to:
  /// **'Their record'**
  String get workerStanding;

  /// No description provided for @jobsCompleted.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No jobs finished yet} =1{1 job finished} other{{count} jobs finished}}'**
  String jobsCompleted(int count);

  /// No description provided for @averageFare.
  ///
  /// In en, this message translates to:
  /// **'Usually charges around {amount}'**
  String averageFare(String amount);

  /// Shown for a worker nobody has rated
  ///
  /// In en, this message translates to:
  /// **'Not rated yet'**
  String get notRatedYet;

  /// Shown for a worker with no history
  ///
  /// In en, this message translates to:
  /// **'New to Trust Hire'**
  String get newToTrustHire;

  /// Heading for the account switcher
  ///
  /// In en, this message translates to:
  /// **'Demo accounts'**
  String get demoAccounts;

  /// Explains why an app with no accounts has an account switcher
  ///
  /// In en, this message translates to:
  /// **'Signing in comes later. For now you can be any of these people — post a job as one, make an offer as another, and see both sides of the same hire.'**
  String get demoAccountsExplain;

  /// Name of the account the app starts on
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get accountYou;

  /// No description provided for @accountYouHelp.
  ///
  /// In en, this message translates to:
  /// **'The account this device started on'**
  String get accountYouHelp;

  /// No description provided for @switchAccount.
  ///
  /// In en, this message translates to:
  /// **'Switch account'**
  String get switchAccount;

  /// No description provided for @nowActingAs.
  ///
  /// In en, this message translates to:
  /// **'You are now {name}'**
  String nowActingAs(String name);

  /// No description provided for @accountPostings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No jobs posted} =1{1 job posted} other{{count} jobs posted}}'**
  String accountPostings(int count);

  /// Heading for your own rating, completed count and fare average
  ///
  /// In en, this message translates to:
  /// **'Your record'**
  String get yourStanding;

  /// Activity tab holding the jobs you have bid on
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get offersTab;

  /// No description provided for @noOffers.
  ///
  /// In en, this message translates to:
  /// **'No offers yet'**
  String get noOffers;

  /// No description provided for @noOffersMessage.
  ///
  /// In en, this message translates to:
  /// **'Open a job and name your price. Offers you make show up here.'**
  String get noOffersMessage;

  /// No description provided for @offerWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get offerWaiting;

  /// No description provided for @offerNotChosen.
  ///
  /// In en, this message translates to:
  /// **'Not chosen'**
  String get offerNotChosen;

  /// No description provided for @acceptBooking.
  ///
  /// In en, this message translates to:
  /// **'Accept this booking'**
  String get acceptBooking;

  /// No description provided for @declineBooking.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineBooking;

  /// No description provided for @declineBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this booking?'**
  String get declineBookingTitle;

  /// No description provided for @declineBookingExplanation.
  ///
  /// In en, this message translates to:
  /// **'The person who booked you will be told, and can book someone else. Nothing is charged for declining.'**
  String get declineBookingExplanation;

  /// No description provided for @bookingRequest.
  ///
  /// In en, this message translates to:
  /// **'Booked directly with you'**
  String get bookingRequest;

  /// No description provided for @bookingAwaitingWorker.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the worker to accept'**
  String get bookingAwaitingWorker;

  /// No description provided for @bookedFrom.
  ///
  /// In en, this message translates to:
  /// **'Booked from the directory'**
  String get bookedFrom;

  /// No description provided for @navDirectory.
  ///
  /// In en, this message translates to:
  /// **'Directory'**
  String get navDirectory;

  /// No description provided for @directoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Book a professional'**
  String get directoryTitle;

  /// No description provided for @directoryIntro.
  ///
  /// In en, this message translates to:
  /// **'Set prices, no haggling. Book someone directly and they say yes or no.'**
  String get directoryIntro;

  /// No description provided for @directoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nobody listed here yet'**
  String get directoryEmpty;

  /// No description provided for @directoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'The directory holds workers who list fixed prices. Try another kind of work, or post a job on the map instead.'**
  String get directoryEmptyMessage;

  /// No description provided for @directoryAllWork.
  ///
  /// In en, this message translates to:
  /// **'All work'**
  String get directoryAllWork;

  /// No description provided for @searchDirectory.
  ///
  /// In en, this message translates to:
  /// **'Search by name or service'**
  String get searchDirectory;

  /// No description provided for @directoryOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get directoryOrderLabel;

  /// No description provided for @directoryOrderByName.
  ///
  /// In en, this message translates to:
  /// **'By name'**
  String get directoryOrderByName;

  /// No description provided for @directoryOrderByDistance.
  ///
  /// In en, this message translates to:
  /// **'Nearest first'**
  String get directoryOrderByDistance;

  /// No description provided for @directoryOrderByPrice.
  ///
  /// In en, this message translates to:
  /// **'Cheapest first'**
  String get directoryOrderByPrice;

  /// No description provided for @directoryWithinReach.
  ///
  /// In en, this message translates to:
  /// **'Only people who travel to me'**
  String get directoryWithinReach;

  /// No description provided for @directoryWithinReachOff.
  ///
  /// In en, this message translates to:
  /// **'Showing everyone, including people who do not travel this far.'**
  String get directoryWithinReachOff;

  /// No description provided for @directoryNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches that'**
  String get directoryNoMatch;

  /// No description provided for @directoryNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try fewer words, another kind of work, or turn off \"Only people who travel to me\".'**
  String get directoryNoMatchMessage;

  /// No description provided for @directoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No one} =1{1 person} other{{count} people}}'**
  String directoryCount(int count);

  /// No description provided for @travelsUpTo.
  ///
  /// In en, this message translates to:
  /// **'Travels up to {distance}'**
  String travelsUpTo(String distance);

  /// No description provided for @worksRemotely.
  ///
  /// In en, this message translates to:
  /// **'Works remotely'**
  String get worksRemotely;

  /// No description provided for @fromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {amount}'**
  String fromPrice(String amount);

  /// No description provided for @serviceMenu.
  ///
  /// In en, this message translates to:
  /// **'What they do'**
  String get serviceMenu;

  /// No description provided for @credentialsHeading.
  ///
  /// In en, this message translates to:
  /// **'Qualifications and experience'**
  String get credentialsHeading;

  /// No description provided for @credentialsUnverified.
  ///
  /// In en, this message translates to:
  /// **'Given by the worker. Trust Hire has not checked these.'**
  String get credentialsUnverified;

  /// No description provided for @serviceAreaHeading.
  ///
  /// In en, this message translates to:
  /// **'Where they work'**
  String get serviceAreaHeading;

  /// No description provided for @serviceAreaRadius.
  ///
  /// In en, this message translates to:
  /// **'Travels up to {distance}'**
  String serviceAreaRadius(String distance);

  /// No description provided for @serviceAreaRemote.
  ///
  /// In en, this message translates to:
  /// **'Works remotely — no travel needed'**
  String get serviceAreaRemote;

  /// No description provided for @bookThis.
  ///
  /// In en, this message translates to:
  /// **'Book this'**
  String get bookThis;

  /// No description provided for @bookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Book {service}'**
  String bookingTitle(String service);

  /// No description provided for @bookingListPrice.
  ///
  /// In en, this message translates to:
  /// **'Their price'**
  String get bookingListPrice;

  /// No description provided for @bookingYouPay.
  ///
  /// In en, this message translates to:
  /// **'You pay'**
  String get bookingYouPay;

  /// No description provided for @bookingSaving.
  ///
  /// In en, this message translates to:
  /// **'You save {amount} by booking here.'**
  String bookingSaving(String amount);

  /// No description provided for @bookingDiscountWhy.
  ///
  /// In en, this message translates to:
  /// **'Trust Hire gives you half of its own fee back. The worker is paid the same either way.'**
  String get bookingDiscountWhy;

  /// No description provided for @bookingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Send this booking'**
  String get bookingConfirm;

  /// No description provided for @bookingSent.
  ///
  /// In en, this message translates to:
  /// **'Booking sent. {name} will accept or decline.'**
  String bookingSent(String name);

  /// No description provided for @bookingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This listing has changed. Open it again to see the current prices.'**
  String get bookingUnavailable;

  /// No description provided for @myListing.
  ///
  /// In en, this message translates to:
  /// **'My directory listing'**
  String get myListing;

  /// No description provided for @myListingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing listed} =1{1 service listed} other{{count} services listed}}'**
  String myListingSubtitle(int count);

  /// No description provided for @premiumHeading.
  ///
  /// In en, this message translates to:
  /// **'Be found in the directory'**
  String get premiumHeading;

  /// No description provided for @premiumPitch.
  ///
  /// In en, this message translates to:
  /// **'Hirers search the directory and book you at your own price — no bidding. Listing is a subscription.'**
  String get premiumPitch;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Listed until {date}'**
  String premiumActive(String date);

  /// No description provided for @premiumDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Ends today} =1{1 day left} other{{count} days left}}'**
  String premiumDaysLeft(int count);

  /// No description provided for @premiumLapsed.
  ///
  /// In en, this message translates to:
  /// **'Your listing has ended. Jobs already booked are unaffected, and you can still bid as normal.'**
  String get premiumLapsed;

  /// No description provided for @premiumMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get premiumMonthly;

  /// No description provided for @premiumYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get premiumYearly;

  /// No description provided for @premiumSimulated.
  ///
  /// In en, this message translates to:
  /// **'Nothing is charged. This is a demonstration and takes no card details.'**
  String get premiumSimulated;

  /// No description provided for @premiumStarted.
  ///
  /// In en, this message translates to:
  /// **'You are in the directory.'**
  String get premiumStarted;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add a service'**
  String get addService;

  /// No description provided for @serviceTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'What is it'**
  String get serviceTitleLabel;

  /// No description provided for @servicePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Your price, in rupees'**
  String get servicePriceLabel;

  /// No description provided for @serviceDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Anything else about it (optional)'**
  String get serviceDescriptionLabel;

  /// No description provided for @serviceKindLabel.
  ///
  /// In en, this message translates to:
  /// **'What kind of work'**
  String get serviceKindLabel;

  /// No description provided for @saveService.
  ///
  /// In en, this message translates to:
  /// **'Add it'**
  String get saveService;

  /// No description provided for @removeService.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeService;

  /// No description provided for @noServicesYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing listed yet'**
  String get noServicesYet;

  /// No description provided for @noServicesYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Add what you do and what you charge. Hirers book these at the price you set.'**
  String get noServicesYetMessage;

  /// No description provided for @addCredential.
  ///
  /// In en, this message translates to:
  /// **'Add a qualification'**
  String get addCredential;

  /// No description provided for @credentialTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'What it is'**
  String get credentialTitleLabel;

  /// No description provided for @credentialIssuerLabel.
  ///
  /// In en, this message translates to:
  /// **'Who gave it (optional)'**
  String get credentialIssuerLabel;

  /// No description provided for @credentialYearLabel.
  ///
  /// In en, this message translates to:
  /// **'Year (optional)'**
  String get credentialYearLabel;

  /// No description provided for @credentialKindQualification.
  ///
  /// In en, this message translates to:
  /// **'Qualification'**
  String get credentialKindQualification;

  /// No description provided for @credentialKindCertification.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get credentialKindCertification;

  /// No description provided for @credentialKindExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get credentialKindExperience;

  /// No description provided for @credentialKindMembership.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get credentialKindMembership;

  /// No description provided for @howFarYouTravel.
  ///
  /// In en, this message translates to:
  /// **'How far you travel'**
  String get howFarYouTravel;

  /// No description provided for @remoteOnlyLabel.
  ///
  /// In en, this message translates to:
  /// **'I work remotely, no travel'**
  String get remoteOnlyLabel;

  /// No description provided for @whereYouWorkFrom.
  ///
  /// In en, this message translates to:
  /// **'Where you travel from'**
  String get whereYouWorkFrom;

  /// No description provided for @whereYouWorkFromHelp.
  ///
  /// In en, this message translates to:
  /// **'Your radius is measured from here. Only the area is shown, never an address.'**
  String get whereYouWorkFromHelp;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useMyLocation;

  /// No description provided for @workFromNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set — you appear to everyone, wherever they are'**
  String get workFromNotSet;

  /// No description provided for @workFromSet.
  ///
  /// In en, this message translates to:
  /// **'Set. People further than your radius will not see you.'**
  String get workFromSet;

  /// No description provided for @listingNeedsService.
  ///
  /// In en, this message translates to:
  /// **'Add at least one service before hirers can find you.'**
  String get listingNeedsService;

  /// Stands in for a name the app does not have
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// What happens after a booking is sent
  ///
  /// In en, this message translates to:
  /// **'They will accept or decline. Nothing is charged either way.'**
  String get bookingWhatNext;

  /// Ledger label for a manual admin correction
  ///
  /// In en, this message translates to:
  /// **'Adjusted by Trust Hire'**
  String get walletAdminAdjustment;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminPanel;

  /// No description provided for @adminSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing waiting} =1{1 thing waiting} other{{count} things waiting}}'**
  String adminSubtitle(int count);

  /// No description provided for @adminTabUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminTabUsers;

  /// No description provided for @adminTabDisputes.
  ///
  /// In en, this message translates to:
  /// **'Disputes'**
  String get adminTabDisputes;

  /// No description provided for @adminTabJobs.
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get adminTabJobs;

  /// No description provided for @adminTabLog.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get adminTabLog;

  /// No description provided for @adminQueueEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to review'**
  String get adminQueueEmpty;

  /// No description provided for @adminQueueEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'New accounts appear here when somebody signs up.'**
  String get adminQueueEmptyMessage;

  /// No description provided for @adminApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminApprove;

  /// No description provided for @adminSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get adminSuspend;

  /// No description provided for @adminReinstate.
  ///
  /// In en, this message translates to:
  /// **'Put back'**
  String get adminReinstate;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get statusPending;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get statusSuspended;

  /// No description provided for @signalCnicOnFile.
  ///
  /// In en, this message translates to:
  /// **'CNIC uploaded'**
  String get signalCnicOnFile;

  /// No description provided for @signalCnicMissing.
  ///
  /// In en, this message translates to:
  /// **'No CNIC'**
  String get signalCnicMissing;

  /// No description provided for @signalCnicShape.
  ///
  /// In en, this message translates to:
  /// **'Number looks right'**
  String get signalCnicShape;

  /// No description provided for @signalPhoneVerified.
  ///
  /// In en, this message translates to:
  /// **'Phone confirmed'**
  String get signalPhoneVerified;

  /// No description provided for @signalPhoneUnverified.
  ///
  /// In en, this message translates to:
  /// **'Phone not confirmed'**
  String get signalPhoneUnverified;

  /// No description provided for @signalSimMismatch.
  ///
  /// In en, this message translates to:
  /// **'SIM name does not match the CNIC'**
  String get signalSimMismatch;

  /// No description provided for @signalCaveat.
  ///
  /// In en, this message translates to:
  /// **'These are plausibility checks, not identity checks. Trust Hire does not look anybody up on a government database.'**
  String get signalCaveat;

  /// No description provided for @simMismatchCaveat.
  ///
  /// In en, this message translates to:
  /// **'Often a family member\'s SIM. Look before deciding.'**
  String get simMismatchCaveat;

  /// No description provided for @adminOpenCnic.
  ///
  /// In en, this message translates to:
  /// **'Open the CNIC'**
  String get adminOpenCnic;

  /// No description provided for @adminCnicLocked.
  ///
  /// In en, this message translates to:
  /// **'The CNIC can only be opened while there is an open dispute about this person.'**
  String get adminCnicLocked;

  /// No description provided for @adminCnicOpened.
  ///
  /// In en, this message translates to:
  /// **'Opened. This has been recorded in the log.'**
  String get adminCnicOpened;

  /// No description provided for @cnicNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Number on file'**
  String get cnicNumberLabel;

  /// No description provided for @cnicNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name on the card'**
  String get cnicNameLabel;

  /// No description provided for @cnicNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'No photo is shipped with the demo.'**
  String get cnicNoPhoto;

  /// No description provided for @adminNoDisputes.
  ///
  /// In en, this message translates to:
  /// **'No disputes'**
  String get adminNoDisputes;

  /// No description provided for @adminNoDisputesMessage.
  ///
  /// In en, this message translates to:
  /// **'A dispute is raised against a job. It is also the only thing that unlocks a CNIC.'**
  String get adminNoDisputesMessage;

  /// No description provided for @disputeAbout.
  ///
  /// In en, this message translates to:
  /// **'About {name}'**
  String disputeAbout(String name);

  /// No description provided for @disputeRaisedBy.
  ///
  /// In en, this message translates to:
  /// **'Raised by {name}'**
  String disputeRaisedBy(String name);

  /// No description provided for @disputeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get disputeOpen;

  /// No description provided for @disputeClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get disputeClosed;

  /// No description provided for @adminCloseDispute.
  ///
  /// In en, this message translates to:
  /// **'Close it'**
  String get adminCloseDispute;

  /// No description provided for @adminAdjustWallet.
  ///
  /// In en, this message translates to:
  /// **'Adjust the balance'**
  String get adminAdjustWallet;

  /// No description provided for @adminUnlockWallet.
  ///
  /// In en, this message translates to:
  /// **'Unlock the account'**
  String get adminUnlockWallet;

  /// No description provided for @adminWalletLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked out — {amount} owed'**
  String adminWalletLocked(String amount);

  /// No description provided for @adminWalletBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance {amount}'**
  String adminWalletBalance(String amount);

  /// No description provided for @adminNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Why (recorded in the log)'**
  String get adminNoteLabel;

  /// No description provided for @adminNoteRequired.
  ///
  /// In en, this message translates to:
  /// **'An override needs a reason. That is what makes it reviewable.'**
  String get adminNoteRequired;

  /// No description provided for @adminApply.
  ///
  /// In en, this message translates to:
  /// **'Do it'**
  String get adminApply;

  /// No description provided for @adminAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'How many tokens, plus or minus'**
  String get adminAmountLabel;

  /// No description provided for @adminLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet'**
  String get adminLogEmpty;

  /// No description provided for @adminLogEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Every admin action lands here — what it was, who it was about, why, and when.'**
  String get adminLogEmptyMessage;

  /// No description provided for @adminLogIntro.
  ///
  /// In en, this message translates to:
  /// **'Every admin action, oldest at the bottom. Nothing here can be edited or removed.'**
  String get adminLogIntro;

  /// No description provided for @actionApproveUser.
  ///
  /// In en, this message translates to:
  /// **'Approved an account'**
  String get actionApproveUser;

  /// No description provided for @actionSuspendUser.
  ///
  /// In en, this message translates to:
  /// **'Suspended an account'**
  String get actionSuspendUser;

  /// No description provided for @actionReinstateUser.
  ///
  /// In en, this message translates to:
  /// **'Put an account back'**
  String get actionReinstateUser;

  /// No description provided for @actionViewCnic.
  ///
  /// In en, this message translates to:
  /// **'Opened a CNIC'**
  String get actionViewCnic;

  /// No description provided for @actionAdjustWallet.
  ///
  /// In en, this message translates to:
  /// **'Adjusted a balance'**
  String get actionAdjustWallet;

  /// No description provided for @actionUnlockWallet.
  ///
  /// In en, this message translates to:
  /// **'Unlocked an account'**
  String get actionUnlockWallet;

  /// No description provided for @actionCancelJob.
  ///
  /// In en, this message translates to:
  /// **'Cancelled a job'**
  String get actionCancelJob;

  /// No description provided for @actionCloseDispute.
  ///
  /// In en, this message translates to:
  /// **'Closed a dispute'**
  String get actionCloseDispute;

  /// No description provided for @adminJobsIntro.
  ///
  /// In en, this message translates to:
  /// **'Every job on the platform, newest first, with its offers.'**
  String get adminJobsIntro;

  /// No description provided for @adminOffersOn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No offers} =1{1 offer} other{{count} offers}}'**
  String adminOffersOn(int count);

  /// Subtitle for the staff demo account
  ///
  /// In en, this message translates to:
  /// **'Trust Hire\'s own account — the admin panel'**
  String get accountStaffHelp;

  /// What the admin panel holds, on the tile that opens it
  ///
  /// In en, this message translates to:
  /// **'Approvals, disputes and the log'**
  String get adminPanelTile;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @verificationTile.
  ///
  /// In en, this message translates to:
  /// **'CNIC and phone'**
  String get verificationTile;

  /// No description provided for @verificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{done, plural, =0{Nothing submitted yet} =1{1 of 3 steps done} =2{2 of 3 steps done} other{All three steps done}}'**
  String verificationSubtitle(int done);

  /// No description provided for @verificationIntro.
  ///
  /// In en, this message translates to:
  /// **'Two things, and neither is an identity check. Trust Hire confirms that a CNIC number is the right shape and that a phone answers a code. It does not look anybody up.'**
  String get verificationIntro;

  /// No description provided for @verificationWhyBother.
  ///
  /// In en, this message translates to:
  /// **'Hirers see whether a worker has been through this. It is not required to use the app, and skipping it does not hide your jobs.'**
  String get verificationWhyBother;

  /// No description provided for @verifyCnicHeading.
  ///
  /// In en, this message translates to:
  /// **'Your CNIC'**
  String get verifyCnicHeading;

  /// No description provided for @verifyCnicNumber.
  ///
  /// In en, this message translates to:
  /// **'CNIC number'**
  String get verifyCnicNumber;

  /// No description provided for @verifyCnicHint.
  ///
  /// In en, this message translates to:
  /// **'13 digits, with or without dashes'**
  String get verifyCnicHint;

  /// No description provided for @verifyNameOnCard.
  ///
  /// In en, this message translates to:
  /// **'Name, exactly as printed on the card'**
  String get verifyNameOnCard;

  /// No description provided for @verifyDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get verifyDateOfBirth;

  /// No description provided for @verifyChooseDate.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get verifyChooseDate;

  /// No description provided for @verifyCnicPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo of the card'**
  String get verifyCnicPhoto;

  /// No description provided for @verifyCnicPhotoNote.
  ///
  /// In en, this message translates to:
  /// **'No photo is uploaded in this demo. The step is here because the real one stores a picture, and a screen that hides that would be describing a different app.'**
  String get verifyCnicPhotoNote;

  /// No description provided for @verifyCnicSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit CNIC'**
  String get verifyCnicSubmit;

  /// No description provided for @verifyCnicBadNumber.
  ///
  /// In en, this message translates to:
  /// **'That is not 13 digits. Nothing was saved.'**
  String get verifyCnicBadNumber;

  /// No description provided for @verifyCnicDone.
  ///
  /// In en, this message translates to:
  /// **'CNIC submitted'**
  String get verifyCnicDone;

  /// No description provided for @verifyCnicOnFile.
  ///
  /// In en, this message translates to:
  /// **'On file since {date}'**
  String verifyCnicOnFile(String date);

  /// No description provided for @verifyCnicMasked.
  ///
  /// In en, this message translates to:
  /// **'Stored as {masked}'**
  String verifyCnicMasked(String masked);

  /// No description provided for @verifyCnicMaskExplain.
  ///
  /// In en, this message translates to:
  /// **'Only this much is kept. The whole number never leaves this screen — there is nothing the app could do with it, and holding one would be keeping a national identity number for no reason.'**
  String get verifyCnicMaskExplain;

  /// No description provided for @verifyCnicNotPlausible.
  ///
  /// In en, this message translates to:
  /// **'The card is on file, but the automated check could not confirm it. Someone will look.'**
  String get verifyCnicNotPlausible;

  /// No description provided for @verifyCnicPlausible.
  ///
  /// In en, this message translates to:
  /// **'The number is the right shape, and the card has a name and a date of birth.'**
  String get verifyCnicPlausible;

  /// No description provided for @verifyPhoneHeading.
  ///
  /// In en, this message translates to:
  /// **'Your phone'**
  String get verifyPhoneHeading;

  /// No description provided for @verifyPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get verifyPhoneNumber;

  /// No description provided for @verifyPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'03xx xxxxxxx'**
  String get verifyPhoneHint;

  /// No description provided for @verifyPhoneBad.
  ///
  /// In en, this message translates to:
  /// **'That is not a Pakistani mobile number.'**
  String get verifyPhoneBad;

  /// No description provided for @verifySendCode.
  ///
  /// In en, this message translates to:
  /// **'Send me a code'**
  String get verifySendCode;

  /// No description provided for @verifyResendCode.
  ///
  /// In en, this message translates to:
  /// **'Send another'**
  String get verifyResendCode;

  /// No description provided for @verifyResendIn.
  ///
  /// In en, this message translates to:
  /// **'Send another in {seconds}s'**
  String verifyResendIn(int seconds);

  /// No description provided for @verifyCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'The 6-digit code'**
  String get verifyCodeLabel;

  /// No description provided for @verifyCodeSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get verifyCodeSubmit;

  /// No description provided for @verifyCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {phone}'**
  String verifyCodeSentTo(String phone);

  /// No description provided for @verifyCodeWrong.
  ///
  /// In en, this message translates to:
  /// **'That code is not right. {left, plural, =1{1 try left} other{{left} tries left}}'**
  String verifyCodeWrong(int left);

  /// No description provided for @verifyCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'That code has run out. Ask for another.'**
  String get verifyCodeExpired;

  /// No description provided for @verifyCodeSpent.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Ask for a new code.'**
  String get verifyCodeSpent;

  /// No description provided for @verifyPhoneDone.
  ///
  /// In en, this message translates to:
  /// **'Phone confirmed'**
  String get verifyPhoneDone;

  /// No description provided for @verifyPhoneConfirmedOn.
  ///
  /// In en, this message translates to:
  /// **'Confirmed {date}'**
  String verifyPhoneConfirmedOn(String date);

  /// No description provided for @verifyDemoSms.
  ///
  /// In en, this message translates to:
  /// **'In this demo the message appears here instead of arriving by SMS'**
  String get verifyDemoSms;

  /// No description provided for @verifyDemoSmsWhy.
  ///
  /// In en, this message translates to:
  /// **'There is no server yet to send from, so nothing leaves the device. Everything else about this step — the expiry, the tries, the wait before you can ask again — is real.'**
  String get verifyDemoSmsWhy;

  /// No description provided for @verifySimHeading.
  ///
  /// In en, this message translates to:
  /// **'Name on the SIM'**
  String get verifySimHeading;

  /// No description provided for @verifySimMatched.
  ///
  /// In en, this message translates to:
  /// **'The name on your card matches the name on this account.'**
  String get verifySimMatched;

  /// No description provided for @verifySimFlagged.
  ///
  /// In en, this message translates to:
  /// **'The name on your card does not match the name on this account. Someone will look at it — this is not a rejection, and using a family member\'s SIM is an ordinary reason for it.'**
  String get verifySimFlagged;

  /// No description provided for @verifySimNotWired.
  ///
  /// In en, this message translates to:
  /// **'A real check asks the network who a number is registered to. That is not wired up here, so this compares against your account name instead.'**
  String get verifySimNotWired;

  /// No description provided for @verifyLimitNoLookup.
  ///
  /// In en, this message translates to:
  /// **'Nobody has asked NADRA whether this card exists. That check is out of scope.'**
  String get verifyLimitNoLookup;

  /// No description provided for @verifyLimitPhotoUnreviewed.
  ///
  /// In en, this message translates to:
  /// **'Your photo has not been looked at, and will not be unless a dispute is raised about you.'**
  String get verifyLimitPhotoUnreviewed;

  /// No description provided for @verifyLimitSimFlag.
  ///
  /// In en, this message translates to:
  /// **'A name mismatch is a reason for a person to look, not evidence of anything.'**
  String get verifyLimitSimFlag;

  /// No description provided for @verifyStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to be looked at'**
  String get verifyStatusPending;

  /// No description provided for @verifyStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get verifyStatusApproved;

  /// No description provided for @verifyStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get verifyStatusSuspended;

  /// No description provided for @backendSection.
  ///
  /// In en, this message translates to:
  /// **'Backend'**
  String get backendSection;

  /// No description provided for @backendExplain.
  ///
  /// In en, this message translates to:
  /// **'There is no server yet. This is a stand-in that behaves like one — it refuses the same things the real database would, and it can be switched off so you can see what happens when the network goes.'**
  String get backendExplain;

  /// No description provided for @syncSettled.
  ///
  /// In en, this message translates to:
  /// **'Everything is saved'**
  String get syncSettled;

  /// No description provided for @syncSending.
  ///
  /// In en, this message translates to:
  /// **'Sending'**
  String get syncSending;

  /// No description provided for @syncOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection — your work is safe'**
  String get syncOffline;

  /// No description provided for @syncNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Something needs you'**
  String get syncNeedsAttention;

  /// No description provided for @syncWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing waiting} =1{1 change waiting} other{{count} changes waiting}}'**
  String syncWaiting(int count);

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncPretendOffline.
  ///
  /// In en, this message translates to:
  /// **'Pretend there is no connection'**
  String get syncPretendOffline;

  /// No description provided for @syncRefusals.
  ///
  /// In en, this message translates to:
  /// **'Changes that did not go through'**
  String get syncRefusals;

  /// No description provided for @syncAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I have read these'**
  String get syncAcknowledge;

  /// No description provided for @syncNeverPulled.
  ///
  /// In en, this message translates to:
  /// **'Nothing fetched yet'**
  String get syncNeverPulled;

  /// No description provided for @syncLastPulled.
  ///
  /// In en, this message translates to:
  /// **'Last fetched {when}'**
  String syncLastPulled(String when);

  /// No description provided for @refusalFareIsLocked.
  ///
  /// In en, this message translates to:
  /// **'The fare was fixed when the offer was accepted, so it could not be changed.'**
  String get refusalFareIsLocked;

  /// No description provided for @refusalWorkerSwapped.
  ///
  /// In en, this message translates to:
  /// **'Somebody had already been chosen for this job.'**
  String get refusalWorkerSwapped;

  /// No description provided for @refusalOwnJob.
  ///
  /// In en, this message translates to:
  /// **'A job cannot be taken by the person who posted it.'**
  String get refusalOwnJob;

  /// No description provided for @refusalAnotherOfferWon.
  ///
  /// In en, this message translates to:
  /// **'Another offer on this job had already been accepted.'**
  String get refusalAnotherOfferWon;

  /// No description provided for @refusalOfferMismatch.
  ///
  /// In en, this message translates to:
  /// **'This offer does not match what the job records.'**
  String get refusalOfferMismatch;

  /// No description provided for @refusalAppendOnly.
  ///
  /// In en, this message translates to:
  /// **'This is a record of something that happened. It can be added to, never changed.'**
  String get refusalAppendOnly;

  /// No description provided for @refusalCommissionCharged.
  ///
  /// In en, this message translates to:
  /// **'Commission had already been charged for this job.'**
  String get refusalCommissionCharged;

  /// No description provided for @refusalJobNotFinished.
  ///
  /// In en, this message translates to:
  /// **'Only a finished job can be rated.'**
  String get refusalJobNotFinished;

  /// No description provided for @refusalAlreadyRated.
  ///
  /// In en, this message translates to:
  /// **'This job had already been rated from your side.'**
  String get refusalAlreadyRated;

  /// No description provided for @refusalChangedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Somebody else changed this while you were offline, so your change was not applied.'**
  String get refusalChangedElsewhere;

  /// No description provided for @refusalUnreachable.
  ///
  /// In en, this message translates to:
  /// **'This has not been sent yet. It is saved on this device.'**
  String get refusalUnreachable;
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
