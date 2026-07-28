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
  String get filterHowFar => 'How far';

  @override
  String get filterIncludes => 'What it includes';

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
  String get onThisDevice => 'Your posting';

  @override
  String get detailWhen => 'When';

  @override
  String get detailPostedBy => 'Posted by';

  @override
  String get detailKindOfWork => 'Kind of work';

  @override
  String get generalAreaNotice =>
      'This is the general area. The exact spot is shared once a worker is chosen.';

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
      'Choose the general area. Only this area is shown until you choose someone — then they get the exact spot.';

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
  String get saveThisJob => 'Save this job';

  @override
  String get removeFromSaved => 'Remove from saved';

  @override
  String get jobSaved => 'Saved. Find it under Saved.';

  @override
  String get jobUnsaved => 'Removed from saved.';

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
      'Your exact location stays hidden while people are offering. It is shared only with the person you choose.';

  @override
  String get onboardNext => 'Next';

  @override
  String get onboardSkip => 'Skip';

  @override
  String get onboardAllowLocation => 'Share My Location';

  @override
  String get onboardNotNow => 'Not Now';

  @override
  String onboardStepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get showIntroAgain => 'Show Intro Again';

  @override
  String get introReset => 'The intro will show next time you open the app.';

  @override
  String get tagPlumbing => 'Plumbing';

  @override
  String get tagElectrical => 'Electrical';

  @override
  String get tagPainting => 'Painting';

  @override
  String get tagCarpentry => 'Carpentry';

  @override
  String get tagMasonry => 'Masonry';

  @override
  String get tagConstruction => 'Construction';

  @override
  String get tagApplianceRepair => 'Appliance repair';

  @override
  String get tagCleaning => 'Cleaning';

  @override
  String get tagMoving => 'Moving';

  @override
  String get tagDriving => 'Driving';

  @override
  String get tagGardening => 'Gardening';

  @override
  String get tagTailoring => 'Tailoring';

  @override
  String get tagCooking => 'Cooking';

  @override
  String get tagTutoring => 'Tutoring';

  @override
  String get tagSecurity => 'Security';

  @override
  String get tagLegal => 'Legal advice';

  @override
  String get tagMedical => 'Medical';

  @override
  String get tagBeauty => 'Beauty';

  @override
  String get tagMisc => 'General work';

  @override
  String get fieldTags => 'Kind of work';

  @override
  String get tagsHelp => 'Choose 1 to 3. This decides who sees your job.';

  @override
  String get tagsRequired => 'Choose at least one kind of work.';

  @override
  String get roleWorker => 'Looking for work';

  @override
  String get roleHirer => 'Hiring someone';

  @override
  String get myTrades => 'My trades';

  @override
  String get myTradesHelp =>
      'You see general work by default. Add your own trade to see those jobs too.';

  @override
  String get whatBringsYouHere => 'What brings you here';

  @override
  String get roleWorkerHelp => 'You see jobs near you that match your trades.';

  @override
  String get roleHirerHelp => 'You post jobs and choose who does them.';

  @override
  String get generalWorkAlwaysOn =>
      'General work is always on, so you never miss an untagged job.';

  @override
  String tradeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'General work and $count trades',
      one: 'General work and 1 trade',
      zero: 'General work only',
    );
    return '$_temp0';
  }

  @override
  String get noJobsForTrades => 'Nothing here for your trades';

  @override
  String get noJobsForTradesHelp =>
      'Jobs only reach you when they match a trade you do. Add a trade to see more.';

  @override
  String get addATrade => 'Add a trade';

  @override
  String get navActivity => 'Activity';

  @override
  String get navProfile => 'Profile';

  @override
  String get audioOnlyJob => 'Described by voice only';

  @override
  String get audioOnlyJobHelp =>
      'There is no written description of this work. Ask the poster if you cannot play the voice note.';

  @override
  String get addWordsForVoiceNote =>
      'Some people cannot play a voice note. A few words here help them find your job.';

  @override
  String get jobsNearby => 'Work on this map';

  @override
  String get openDetails => 'Open details';

  @override
  String get fieldStartingFare => 'Starting fare';

  @override
  String get startingFareHelp =>
      'Optional. A starting point, not a price — workers will offer their own.';

  @override
  String get fareHint => 'Rs. 2,000';

  @override
  String rupees(String amount) {
    return 'Rs. $amount';
  }

  @override
  String startsAt(String amount) {
    return 'Starts at $amount';
  }

  @override
  String agreedAt(String amount) {
    return 'Agreed at $amount';
  }

  @override
  String get offerAFare => 'Offer a fare';

  @override
  String get changeMyOffer => 'Change my offer';

  @override
  String yourOffer(String fare) {
    return 'You offered $fare';
  }

  @override
  String get sendOffer => 'Send offer';

  @override
  String get withdrawOffer => 'Withdraw';

  @override
  String get offerMessageHint => 'Anything the hirer should know (optional)';

  @override
  String get fareMustBePositive => 'Enter a fare above zero.';

  @override
  String get fareLooksTooHigh => 'That looks like a typo. Check the amount.';

  @override
  String get offersOnThisJob => 'Offers';

  @override
  String offerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offers',
      one: '1 offer',
      zero: 'No offers yet',
    );
    return '$_temp0';
  }

  @override
  String get noOffersYet =>
      'Nobody has offered yet. Workers nearby who do this kind of work will see it.';

  @override
  String get chooseThisWorker => 'Choose';

  @override
  String get chosen => 'Chosen';

  @override
  String get notChosen => 'Not chosen';

  @override
  String get fareLocked =>
      'The fare is fixed once you choose. It cannot be changed afterwards.';

  @override
  String confirmChoose(String amount) {
    return 'Choose this worker at $amount?';
  }

  @override
  String get cannotBidOwnJob => 'This is your own job.';

  @override
  String get cannotBidAccepted => 'This job has been given to someone.';

  @override
  String get offerWithdrawn => 'Withdrawn';

  @override
  String get cancel => 'Cancel';

  @override
  String get statusOpen => 'Taking offers';

  @override
  String get statusAccepted => 'Worker chosen';

  @override
  String get statusInProgress => 'Under way';

  @override
  String get statusCompleted => 'Finished';

  @override
  String get statusCancelled => 'Called off';

  @override
  String get statusExpired => 'No longer listed';

  @override
  String get confirmArrival => 'They have arrived';

  @override
  String get markComplete => 'Work is finished';

  @override
  String get cancelJob => 'Call this off';

  @override
  String get cancelJobExplanation =>
      'The other person will be told. This cannot be undone.';

  @override
  String get exactLocationShown =>
      'This is the exact spot, shared because you two are working together.';

  @override
  String get jobFinished => 'This work is finished.';

  @override
  String get jobCalledOff => 'This work was called off.';

  @override
  String get jobExpired => 'Nobody was chosen, so this is no longer listed.';

  @override
  String get navWallet => 'Wallet';

  @override
  String get walletBalance => 'Balance';

  @override
  String get walletTopUp => 'Top-up';

  @override
  String get walletCommission => 'Commission';

  @override
  String get walletFirstJobCredit => 'First job credit';

  @override
  String get walletLoyaltyBonus => 'Loyalty bonus';

  @override
  String get walletCancellationPenalty => 'Cancellation charge';

  @override
  String get walletExplanation =>
      'Trust Hire takes 5% of the agreed fare when a job is finished. Tokens are not real money.';

  @override
  String walletInDebt(String amount) {
    return 'You owe $amount. You can still take one more job before your account is paused.';
  }

  @override
  String get walletLocked =>
      'Your account is paused until you clear what you owe. Top up to start getting work again.';

  @override
  String get walletEmpty =>
      'Nothing has moved yet. Your first job\'s commission will show up here.';

  @override
  String get topUpTitle => 'Add tokens';

  @override
  String get topUpNotReal =>
      'This is a demonstration. No real payment is taken and no card details are asked for.';

  @override
  String topUpConfirm(String amount) {
    return 'Add $amount';
  }

  @override
  String topUpDone(String amount) {
    return '$amount added to your wallet.';
  }

  @override
  String loyaltyProgress(String amount) {
    return '$amount more in top-ups earns a 1,000 token bonus.';
  }

  @override
  String firstJobCreditWaiting(String amount) {
    return 'Your first job\'s commission is covered up to $amount.';
  }

  @override
  String get rateThisJob => 'How did it go?';

  @override
  String get rateWorker => 'Rate the person who did the work';

  @override
  String get rateHirer => 'Rate the person who hired you';

  @override
  String get rateHirerPrivate =>
      'This is not shown to them or to anyone else. It helps us spot people who cause trouble.';

  @override
  String get rateWorkerPublic => 'This is shown on their profile.';

  @override
  String get rateNoteHint => 'Anything we should know (optional)';

  @override
  String get sendRating => 'Send';

  @override
  String get ratingThanks => 'Thank you.';

  @override
  String starsChosen(int count) {
    return '$count of 5';
  }

  @override
  String get alreadyRated => 'You have rated this job.';

  @override
  String get workerStanding => 'Their record';

  @override
  String jobsCompleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs finished',
      one: '1 job finished',
      zero: 'No jobs finished yet',
    );
    return '$_temp0';
  }

  @override
  String averageFare(String amount) {
    return 'Usually charges around $amount';
  }

  @override
  String get notRatedYet => 'Not rated yet';

  @override
  String get newToTrustHire => 'New to Trust Hire';

  @override
  String get demoAccounts => 'Demo accounts';

  @override
  String get demoAccountsExplain =>
      'Signing in comes later. For now you can be any of these people — post a job as one, make an offer as another, and see both sides of the same hire.';

  @override
  String get accountYou => 'You';

  @override
  String get accountYouHelp => 'The account this device started on';

  @override
  String get switchAccount => 'Switch account';

  @override
  String nowActingAs(String name) {
    return 'You are now $name';
  }

  @override
  String accountPostings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs posted',
      one: '1 job posted',
      zero: 'No jobs posted',
    );
    return '$_temp0';
  }

  @override
  String get yourStanding => 'Your record';

  @override
  String get offersTab => 'Offers';

  @override
  String get noOffers => 'No offers yet';

  @override
  String get noOffersMessage =>
      'Open a job and name your price. Offers you make show up here.';

  @override
  String get offerWaiting => 'Waiting';

  @override
  String get offerNotChosen => 'Not chosen';

  @override
  String get acceptBooking => 'Accept this booking';

  @override
  String get declineBooking => 'Decline';

  @override
  String get declineBookingTitle => 'Decline this booking?';

  @override
  String get declineBookingExplanation =>
      'The person who booked you will be told, and can book someone else. Nothing is charged for declining.';

  @override
  String get bookingRequest => 'Booked directly with you';

  @override
  String get bookingAwaitingWorker => 'Waiting for the worker to accept';

  @override
  String get bookedFrom => 'Booked from the directory';

  @override
  String get navDirectory => 'Directory';

  @override
  String get directoryTitle => 'Book a professional';

  @override
  String get directoryIntro =>
      'Set prices, no haggling. Book someone directly and they say yes or no.';

  @override
  String get directoryEmpty => 'Nobody listed here yet';

  @override
  String get directoryEmptyMessage =>
      'The directory holds workers who list fixed prices. Try another kind of work, or post a job on the map instead.';

  @override
  String get directoryAllWork => 'All work';

  @override
  String fromPrice(String amount) {
    return 'From $amount';
  }

  @override
  String get serviceMenu => 'What they do';

  @override
  String get credentialsHeading => 'Qualifications and experience';

  @override
  String get credentialsUnverified =>
      'Given by the worker. Trust Hire has not checked these.';

  @override
  String get serviceAreaHeading => 'Where they work';

  @override
  String serviceAreaRadius(String distance) {
    return 'Travels up to $distance';
  }

  @override
  String get serviceAreaRemote => 'Works remotely — no travel needed';

  @override
  String get bookThis => 'Book this';

  @override
  String bookingTitle(String service) {
    return 'Book $service';
  }

  @override
  String get bookingListPrice => 'Their price';

  @override
  String get bookingYouPay => 'You pay';

  @override
  String bookingSaving(String amount) {
    return 'You save $amount by booking here.';
  }

  @override
  String get bookingDiscountWhy =>
      'Trust Hire gives you half of its own fee back. The worker is paid the same either way.';

  @override
  String get bookingConfirm => 'Send this booking';

  @override
  String bookingSent(String name) {
    return 'Booking sent. $name will accept or decline.';
  }

  @override
  String get bookingUnavailable =>
      'This listing has changed. Open it again to see the current prices.';

  @override
  String get myListing => 'My directory listing';

  @override
  String myListingSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services listed',
      one: '1 service listed',
      zero: 'Nothing listed',
    );
    return '$_temp0';
  }

  @override
  String get premiumHeading => 'Be found in the directory';

  @override
  String get premiumPitch =>
      'Hirers search the directory and book you at your own price — no bidding. Listing is a subscription.';

  @override
  String premiumActive(String date) {
    return 'Listed until $date';
  }

  @override
  String premiumDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
      zero: 'Ends today',
    );
    return '$_temp0';
  }

  @override
  String get premiumLapsed =>
      'Your listing has ended. Jobs already booked are unaffected, and you can still bid as normal.';

  @override
  String get premiumMonthly => 'Monthly';

  @override
  String get premiumYearly => 'Yearly';

  @override
  String get premiumSimulated =>
      'Nothing is charged. This is a demonstration and takes no card details.';

  @override
  String get premiumStarted => 'You are in the directory.';

  @override
  String get addService => 'Add a service';

  @override
  String get serviceTitleLabel => 'What is it';

  @override
  String get servicePriceLabel => 'Your price, in rupees';

  @override
  String get serviceDescriptionLabel => 'Anything else about it (optional)';

  @override
  String get serviceKindLabel => 'What kind of work';

  @override
  String get saveService => 'Add it';

  @override
  String get removeService => 'Remove';

  @override
  String get noServicesYet => 'Nothing listed yet';

  @override
  String get noServicesYetMessage =>
      'Add what you do and what you charge. Hirers book these at the price you set.';

  @override
  String get addCredential => 'Add a qualification';

  @override
  String get credentialTitleLabel => 'What it is';

  @override
  String get credentialIssuerLabel => 'Who gave it (optional)';

  @override
  String get credentialYearLabel => 'Year (optional)';

  @override
  String get credentialKindQualification => 'Qualification';

  @override
  String get credentialKindCertification => 'Certificate';

  @override
  String get credentialKindExperience => 'Experience';

  @override
  String get credentialKindMembership => 'Membership';

  @override
  String get howFarYouTravel => 'How far you travel';

  @override
  String get remoteOnlyLabel => 'I work remotely, no travel';

  @override
  String get listingNeedsService =>
      'Add at least one service before hirers can find you.';

  @override
  String get someone => 'Someone';

  @override
  String get bookingWhatNext =>
      'They will accept or decline. Nothing is charged either way.';

  @override
  String get walletAdminAdjustment => 'Adjusted by Trust Hire';

  @override
  String get adminPanel => 'Admin';

  @override
  String adminSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count things waiting',
      one: '1 thing waiting',
      zero: 'Nothing waiting',
    );
    return '$_temp0';
  }

  @override
  String get adminTabUsers => 'Users';

  @override
  String get adminTabDisputes => 'Disputes';

  @override
  String get adminTabJobs => 'Jobs';

  @override
  String get adminTabLog => 'Log';

  @override
  String get adminQueueEmpty => 'Nothing to review';

  @override
  String get adminQueueEmptyMessage =>
      'New accounts appear here when somebody signs up.';

  @override
  String get adminApprove => 'Approve';

  @override
  String get adminSuspend => 'Suspend';

  @override
  String get adminReinstate => 'Put back';

  @override
  String get statusPending => 'Waiting';

  @override
  String get statusApproved => 'Approved';

  @override
  String get statusSuspended => 'Suspended';

  @override
  String get signalCnicOnFile => 'CNIC uploaded';

  @override
  String get signalCnicMissing => 'No CNIC';

  @override
  String get signalCnicShape => 'Number looks right';

  @override
  String get signalPhoneVerified => 'Phone confirmed';

  @override
  String get signalPhoneUnverified => 'Phone not confirmed';

  @override
  String get signalSimMismatch => 'SIM name does not match the CNIC';

  @override
  String get signalCaveat =>
      'These are plausibility checks, not identity checks. Trust Hire does not look anybody up on a government database.';

  @override
  String get simMismatchCaveat =>
      'Often a family member\'s SIM. Look before deciding.';

  @override
  String get adminOpenCnic => 'Open the CNIC';

  @override
  String get adminCnicLocked =>
      'The CNIC can only be opened while there is an open dispute about this person.';

  @override
  String get adminCnicOpened => 'Opened. This has been recorded in the log.';

  @override
  String get cnicNumberLabel => 'Number on file';

  @override
  String get cnicNameLabel => 'Name on the card';

  @override
  String get cnicNoPhoto => 'No photo is shipped with the demo.';

  @override
  String get adminNoDisputes => 'No disputes';

  @override
  String get adminNoDisputesMessage =>
      'A dispute is raised against a job. It is also the only thing that unlocks a CNIC.';

  @override
  String disputeAbout(String name) {
    return 'About $name';
  }

  @override
  String disputeRaisedBy(String name) {
    return 'Raised by $name';
  }

  @override
  String get disputeOpen => 'Open';

  @override
  String get disputeClosed => 'Closed';

  @override
  String get adminCloseDispute => 'Close it';

  @override
  String get adminAdjustWallet => 'Adjust the balance';

  @override
  String get adminUnlockWallet => 'Unlock the account';

  @override
  String adminWalletLocked(String amount) {
    return 'Locked out — $amount owed';
  }

  @override
  String adminWalletBalance(String amount) {
    return 'Balance $amount';
  }

  @override
  String get adminNoteLabel => 'Why (recorded in the log)';

  @override
  String get adminNoteRequired =>
      'An override needs a reason. That is what makes it reviewable.';

  @override
  String get adminApply => 'Do it';

  @override
  String get adminAmountLabel => 'How many tokens, plus or minus';

  @override
  String get adminLogEmpty => 'Nothing logged yet';

  @override
  String get adminLogEmptyMessage =>
      'Every admin action lands here — what it was, who it was about, why, and when.';

  @override
  String get adminLogIntro =>
      'Every admin action, oldest at the bottom. Nothing here can be edited or removed.';

  @override
  String get actionApproveUser => 'Approved an account';

  @override
  String get actionSuspendUser => 'Suspended an account';

  @override
  String get actionReinstateUser => 'Put an account back';

  @override
  String get actionViewCnic => 'Opened a CNIC';

  @override
  String get actionAdjustWallet => 'Adjusted a balance';

  @override
  String get actionUnlockWallet => 'Unlocked an account';

  @override
  String get actionCancelJob => 'Cancelled a job';

  @override
  String get actionCloseDispute => 'Closed a dispute';

  @override
  String get adminJobsIntro =>
      'Every job on the platform, newest first, with its offers.';

  @override
  String adminOffersOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offers',
      one: '1 offer',
      zero: 'No offers',
    );
    return '$_temp0';
  }

  @override
  String get accountStaffHelp => 'Trust Hire\'s own account — the admin panel';

  @override
  String get adminPanelTile => 'Approvals, disputes and the log';

  @override
  String get verification => 'Verification';

  @override
  String get verificationTile => 'CNIC and phone';

  @override
  String verificationSubtitle(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'All three steps done',
      two: '2 of 3 steps done',
      one: '1 of 3 steps done',
      zero: 'Nothing submitted yet',
    );
    return '$_temp0';
  }

  @override
  String get verificationIntro =>
      'Two things, and neither is an identity check. Trust Hire confirms that a CNIC number is the right shape and that a phone answers a code. It does not look anybody up.';

  @override
  String get verificationWhyBother =>
      'Hirers see whether a worker has been through this. It is not required to use the app, and skipping it does not hide your jobs.';

  @override
  String get verifyCnicHeading => 'Your CNIC';

  @override
  String get verifyCnicNumber => 'CNIC number';

  @override
  String get verifyCnicHint => '13 digits, with or without dashes';

  @override
  String get verifyNameOnCard => 'Name, exactly as printed on the card';

  @override
  String get verifyDateOfBirth => 'Date of birth';

  @override
  String get verifyChooseDate => 'Choose';

  @override
  String get verifyCnicPhoto => 'Photo of the card';

  @override
  String get verifyCnicPhotoNote =>
      'No photo is uploaded in this demo. The step is here because the real one stores a picture, and a screen that hides that would be describing a different app.';

  @override
  String get verifyCnicSubmit => 'Submit CNIC';

  @override
  String get verifyCnicBadNumber => 'That is not 13 digits. Nothing was saved.';

  @override
  String get verifyCnicDone => 'CNIC submitted';

  @override
  String verifyCnicOnFile(String date) {
    return 'On file since $date';
  }

  @override
  String verifyCnicMasked(String masked) {
    return 'Stored as $masked';
  }

  @override
  String get verifyCnicMaskExplain =>
      'Only this much is kept. The whole number never leaves this screen — there is nothing the app could do with it, and holding one would be keeping a national identity number for no reason.';

  @override
  String get verifyCnicNotPlausible =>
      'The card is on file, but the automated check could not confirm it. Someone will look.';

  @override
  String get verifyCnicPlausible =>
      'The number is the right shape, and the card has a name and a date of birth.';

  @override
  String get verifyPhoneHeading => 'Your phone';

  @override
  String get verifyPhoneNumber => 'Mobile number';

  @override
  String get verifyPhoneHint => '03xx xxxxxxx';

  @override
  String get verifyPhoneBad => 'That is not a Pakistani mobile number.';

  @override
  String get verifySendCode => 'Send me a code';

  @override
  String get verifyResendCode => 'Send another';

  @override
  String verifyResendIn(int seconds) {
    return 'Send another in ${seconds}s';
  }

  @override
  String get verifyCodeLabel => 'The 6-digit code';

  @override
  String get verifyCodeSubmit => 'Confirm';

  @override
  String verifyCodeSentTo(String phone) {
    return 'Sent to $phone';
  }

  @override
  String verifyCodeWrong(int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left tries left',
      one: '1 try left',
    );
    return 'That code is not right. $_temp0';
  }

  @override
  String get verifyCodeExpired => 'That code has run out. Ask for another.';

  @override
  String get verifyCodeSpent => 'Too many tries. Ask for a new code.';

  @override
  String get verifyPhoneDone => 'Phone confirmed';

  @override
  String verifyPhoneConfirmedOn(String date) {
    return 'Confirmed $date';
  }

  @override
  String get verifyDemoSms =>
      'In this demo the message appears here instead of arriving by SMS';

  @override
  String get verifyDemoSmsWhy =>
      'There is no server yet to send from, so nothing leaves the device. Everything else about this step — the expiry, the tries, the wait before you can ask again — is real.';

  @override
  String get verifySimHeading => 'Name on the SIM';

  @override
  String get verifySimMatched =>
      'The name on your card matches the name on this account.';

  @override
  String get verifySimFlagged =>
      'The name on your card does not match the name on this account. Someone will look at it — this is not a rejection, and using a family member\'s SIM is an ordinary reason for it.';

  @override
  String get verifySimNotWired =>
      'A real check asks the network who a number is registered to. That is not wired up here, so this compares against your account name instead.';

  @override
  String get verifyLimitNoLookup =>
      'Nobody has asked NADRA whether this card exists. That check is out of scope.';

  @override
  String get verifyLimitPhotoUnreviewed =>
      'Your photo has not been looked at, and will not be unless a dispute is raised about you.';

  @override
  String get verifyLimitSimFlag =>
      'A name mismatch is a reason for a person to look, not evidence of anything.';

  @override
  String get verifyStatusPending => 'Waiting to be looked at';

  @override
  String get verifyStatusApproved => 'Approved';

  @override
  String get verifyStatusSuspended => 'Suspended';
}
