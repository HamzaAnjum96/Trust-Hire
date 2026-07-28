// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppStringsUr extends AppStrings {
  AppStringsUr([String locale = 'ur']) : super(locale);

  @override
  String get appTitle => 'ٹرسٹ ہائر';

  @override
  String get languageName => 'اردو';

  @override
  String get navMap => 'نقشہ';

  @override
  String get navJobs => 'کام';

  @override
  String get navSettings => 'ترتیبات';

  @override
  String get postAJob => 'کام لگائیں';

  @override
  String get nearbyWork => 'قریبی کام';

  @override
  String get findWork => 'کام تلاش کریں';

  @override
  String jobCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کام',
      one: '1 کام',
    );
    return '$_temp0';
  }

  @override
  String jobCountFiltered(int shown, int total) {
    return '$total میں سے $shown';
  }

  @override
  String get loadingJobs => 'قریبی کام لوڈ ہو رہے ہیں…';

  @override
  String get couldNotLoadJobs =>
      'کام لوڈ نہیں ہو سکے۔ دوبارہ کوشش کے لیے نیچے کھینچیں۔';

  @override
  String get close => 'بند کریں';

  @override
  String get dismiss => 'ہٹا دیں';

  @override
  String get showAllJobs => 'سارے کام دکھائیں';

  @override
  String get nearMeLabel => 'میرے قریب';

  @override
  String clusterLabel(int count) {
    return 'یہاں $count کام ہیں۔ قریب سے دیکھنے کے لیے دبائیں۔';
  }

  @override
  String get mapLabel => 'قریبی کاموں کا نقشہ';

  @override
  String get yourLocation => 'آپ کی جگہ';

  @override
  String get mapImagesNotLoading =>
      'نقشے کی تصویریں نہیں آ رہیں۔ کام پھر بھی صحیح جگہ پر دکھائے جا رہے ہیں۔';

  @override
  String get noJobsMatchHere =>
      'یہاں کوئی کام نہیں ملا۔ بڑا علاقہ یا کوئی اور وقت آزمائیں۔';

  @override
  String get locationOff =>
      'جگہ کی اجازت بند ہے۔ آپ پھر بھی نقشہ ہلا کر خود علاقہ چن سکتے ہیں۔';

  @override
  String get locationOffForApp =>
      'اس ایپ کے لیے جگہ کی اجازت بند ہے۔ آپ پھر بھی نقشہ ہلا کر خود علاقہ چن سکتے ہیں۔';

  @override
  String get locationServiceOff =>
      'اس فون پر جگہ کی سہولت بند ہے۔ آپ پھر بھی نقشہ ہلا کر خود علاقہ چن سکتے ہیں۔';

  @override
  String get locationNotFound =>
      'آپ کی جگہ نہیں مل سکی۔ آپ پھر بھی نقشہ ہلا کر خود علاقہ چن سکتے ہیں۔';

  @override
  String get searchJobs => 'کام ڈھونڈیں';

  @override
  String get clearSearch => 'تلاش صاف کریں';

  @override
  String get todaysJobs => 'آج کے کام';

  @override
  String get tomorrow => 'کل';

  @override
  String get thisWeek => 'اس ہفتے';

  @override
  String get anyTime => 'کسی بھی وقت';

  @override
  String get nearMe => 'میرے قریب';

  @override
  String get anyDistance => 'کوئی بھی فاصلہ';

  @override
  String get withinFive => '5 کلومیٹر کے اندر';

  @override
  String get withinTen => '10 کلومیٹر کے اندر';

  @override
  String get voiceNote => 'آواز کا پیغام';

  @override
  String get photos => 'تصویریں';

  @override
  String get more => 'مزید';

  @override
  String get clear => 'صاف کریں';

  @override
  String get clearAll => 'سب صاف کریں';

  @override
  String get clearFilters => 'فلٹر ہٹا دیں';

  @override
  String get showJobs => 'کام دکھائیں';

  @override
  String get filterHowFar => 'کتنی دور';

  @override
  String get filterIncludes => 'اس میں کیا ہے';

  @override
  String get filterKindWarning =>
      'جن کاموں نے اپنی قسم نہیں بتائی وہ چھپ جائیں گے۔';

  @override
  String get noJobsYet => 'ابھی کوئی کام نہیں';

  @override
  String get postTheFirstJob => 'پہلا کام لگائیں تاکہ وہ یہاں دکھے۔';

  @override
  String get noJobsMatch => 'کوئی کام نہیں ملا';

  @override
  String get tryWiderArea => 'بڑا علاقہ یا کوئی اور وقت آزمائیں۔';

  @override
  String postedAgo(String when) {
    return '$when لگایا گیا';
  }

  @override
  String get onThisDevice => 'آپ کی پوسٹ';

  @override
  String get detailWhen => 'کب';

  @override
  String get detailPostedBy => 'لگانے والے';

  @override
  String get detailKindOfWork => 'کام کی قسم';

  @override
  String get generalAreaNotice =>
      'یہ عام علاقہ ہے۔ کام کرنے والا منتخب ہونے پر ٹھیک جگہ بتائی جاتی ہے۔';

  @override
  String get jobNoLongerHere => 'یہ کام اب یہاں نہیں ہے۔';

  @override
  String photoOfCount(int index, int total) {
    return '$total میں سے $index تصویر';
  }

  @override
  String photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count تصویریں',
      one: '1 تصویر',
    );
    return '$_temp0';
  }

  @override
  String get listen => 'سنیں';

  @override
  String get pause => 'روکیں';

  @override
  String get playing => 'چل رہا ہے';

  @override
  String get voiceNoteCouldNotPlay => 'یہ آواز کا پیغام نہیں چل سکا۔';

  @override
  String get postAJobTitle => 'کام لگائیں';

  @override
  String get editJobTitle => 'کام میں تبدیلی';

  @override
  String get whatWorkDoYouNeed => 'آپ کو کیا کام کروانا ہے؟';

  @override
  String get anyOneIsEnough =>
      'آواز کا پیغام، تصویر یا چھوٹا سا پیغام ڈالیں۔ ان میں سے ایک ہی کافی ہے۔';

  @override
  String get tellPeopleAboutTheJob => 'لوگوں کو کام کے بارے میں بتائیں';

  @override
  String get speakNaturally =>
      'آرام سے بولیں۔ پہلے سے کچھ تیار کرنے کی ضرورت نہیں۔';

  @override
  String get recordAVoiceNote => 'آواز کا پیغام ریکارڈ کریں';

  @override
  String get recording => 'ریکارڈ ہو رہا ہے…';

  @override
  String get stopRecording => 'ریکارڈنگ روکیں';

  @override
  String get discard => 'ختم کریں';

  @override
  String get voiceNoteAdded => 'آواز کا پیغام لگ گیا';

  @override
  String get recordAgain => 'دوبارہ ریکارڈ کریں';

  @override
  String get removeVoiceNote => 'آواز کا پیغام ہٹائیں';

  @override
  String get microphoneOff =>
      'مائیک کی اجازت بند ہے۔ آپ پھر بھی تصویر ڈال سکتے ہیں یا چھوٹا پیغام لکھ سکتے ہیں۔';

  @override
  String get takePhoto => 'تصویر کھینچیں';

  @override
  String get choosePhoto => 'تصویر چنیں';

  @override
  String get removePhoto => 'تصویر ہٹائیں';

  @override
  String get fieldTitle => 'عنوان';

  @override
  String get titleHint => 'چھوٹا سا عنوان۔ یہ بعد میں بھی ڈال سکتے ہیں۔';

  @override
  String get fieldMessage => 'پیغام';

  @override
  String get messageHint => 'اور کوئی بات جو بتانی ہو۔';

  @override
  String get fieldArea => 'علاقہ';

  @override
  String get areaHelp =>
      'عام علاقہ چنیں۔ جب تک آپ کسی کو منتخب نہیں کرتے، صرف یہی علاقہ نظر آتا ہے — پھر انہیں ٹھیک جگہ مل جاتی ہے۔';

  @override
  String get moveMapToChooseArea => 'علاقہ چننے کے لیے نقشہ ہلائیں';

  @override
  String get clearTime => 'وقت ہٹا دیں';

  @override
  String get whenIsWorkNeeded => 'کام کب کروانا ہے؟';

  @override
  String get whatTime => 'کس وقت؟';

  @override
  String get addAtLeastOne =>
      'کم از کم ایک آواز کا پیغام، تصویر یا پیغام ڈالیں۔';

  @override
  String get couldNotSave => 'آپ کا کام محفوظ نہیں ہو سکا۔ دوبارہ کوشش کریں۔';

  @override
  String get saveJob => 'کام محفوظ کریں';

  @override
  String get saveChanges => 'تبدیلیاں محفوظ کریں';

  @override
  String get postedOnThisDevice => 'آپ کا کام اسی فون پر لگ گیا ہے۔';

  @override
  String get changesSaved => 'آپ کی تبدیلیاں اسی فون پر محفوظ ہو گئیں۔';

  @override
  String get editJob => 'کام بدلیں';

  @override
  String get deleteJob => 'کام مٹا دیں';

  @override
  String get deleteThisJob => 'یہ کام مٹا دیں؟';

  @override
  String get deleteJobExplanation =>
      'یہ اس فون سے ہٹ جائے گا۔ پھر واپس نہیں آ سکے گا۔';

  @override
  String get keepJob => 'کام رہنے دیں';

  @override
  String get jobDeleted => 'کام اس فون سے مٹا دیا گیا۔';

  @override
  String get settingsStorageNotice =>
      'یہ آزمائشی ایپ کام صرف اسی فون پر رکھتی ہے۔ کچھ بھی اپ لوڈ نہیں ہوتا اور کوئی اکاؤنٹ نہیں چاہیے۔';

  @override
  String get appearance => 'شکل و صورت';

  @override
  String get themeSystem => 'فون کے مطابق';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'گہرا';

  @override
  String get language => 'زبان';

  @override
  String get localData => 'اس فون کا ڈیٹا';

  @override
  String get restoreSeedExplanation =>
      'اصل مثالیں واپس لانے سے آپ کے اس فون پر بنائے ہوئے سارے کام ہٹ جائیں گے۔';

  @override
  String get restoreSeedData => 'اصل مثالیں واپس لائیں';

  @override
  String get restoreSeedTitle => 'اصل مثالیں واپس لائیں؟';

  @override
  String get restoreSeedWarning =>
      'آپ کے اس فون پر بنائے ہوئے کام ہٹ جائیں گے۔ پھر واپس نہیں آ سکیں گے۔';

  @override
  String get keepMyJobs => 'میرے کام رہنے دیں';

  @override
  String get seedRestored => 'اصل مثالیں واپس آ گئیں۔';

  @override
  String get voiceNoteJob => 'آواز والا کام';

  @override
  String get photoJob => 'تصویر والا کام';

  @override
  String get untitledJob => 'بغیر عنوان کام';

  @override
  String get veryClose => 'بہت قریب';

  @override
  String metresAway(int metres) {
    return '$metres میٹر دور';
  }

  @override
  String kilometresAway(String km) {
    return '$km کلومیٹر دور';
  }

  @override
  String metresArea(int metres) {
    return '$metres میٹر کا علاقہ';
  }

  @override
  String kilometresArea(String km) {
    return '$km کلومیٹر کا علاقہ';
  }

  @override
  String todayAt(String time) {
    return 'آج، $time';
  }

  @override
  String tomorrowAt(String time) {
    return 'کل، $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'گزشتہ کل، $time';
  }

  @override
  String dayAt(String day, String time) {
    return '$day، $time';
  }

  @override
  String wasOn(String date) {
    return '$date کو تھا';
  }

  @override
  String get justNow => 'ابھی';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منٹ پہلے',
      one: '1 منٹ پہلے',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count گھنٹے پہلے',
      one: '1 گھنٹہ پہلے',
    );
    return '$_temp0';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دن پہلے',
      one: '1 دن پہلے',
    );
    return '$_temp0';
  }

  @override
  String get contact => 'رابطہ';

  @override
  String get contactShow => 'رابطہ دکھائیں';

  @override
  String get contactHiddenNotice =>
      'رابطے کی تفصیل تبھی دکھائی جاتی ہے جب آپ خود مانگیں۔';

  @override
  String get callNumber => 'کال کریں';

  @override
  String get whatsAppNumber => 'واٹس ایپ';

  @override
  String get copyNumber => 'نمبر کاپی کریں';

  @override
  String get numberCopied => 'نمبر کاپی ہو گیا۔';

  @override
  String get couldNotOpenDialer =>
      'فون ایپ نہیں کھل سکی۔ نمبر اوپر موجود ہے، آپ خود ملا سکتے ہیں۔';

  @override
  String get couldNotOpenWhatsApp =>
      'واٹس ایپ نہیں کھل سکی۔ نمبر اوپر موجود ہے، آپ خود پیغام بھیج سکتے ہیں۔';

  @override
  String get noContactGiven => 'اس کام کے ساتھ رابطے کی کوئی تفصیل نہیں۔';

  @override
  String get fieldContact => 'فون نمبر';

  @override
  String get contactHint =>
      'تاکہ لوگ آپ سے رابطہ کر سکیں۔ یہ بعد میں بھی ڈال سکتے ہیں۔';

  @override
  String get contactHelp => 'صرف انہیں دکھایا جائے گا جو دیکھنے کے لیے دبائیں۔';

  @override
  String get whatsAppMessage =>
      'السلام علیکم، میں نے ٹرسٹ ہائر پر آپ کا کام دیکھا۔';

  @override
  String get saveThisJob => 'یہ کام محفوظ کریں';

  @override
  String get removeFromSaved => 'محفوظ شدہ سے ہٹائیں';

  @override
  String get jobSaved => 'محفوظ ہو گیا۔ اسے محفوظ شدہ میں دیکھیں۔';

  @override
  String get jobUnsaved => 'محفوظ شدہ سے ہٹا دیا گیا۔';

  @override
  String get noSavedJobs => 'ابھی کچھ محفوظ نہیں';

  @override
  String get noSavedJobsMessage => 'کسی کام پر نشان دبائیں تاکہ وہ یہاں رہے۔';

  @override
  String get noPostings => 'آپ نے ابھی کوئی کام نہیں لگایا';

  @override
  String get noPostingsMessage => 'آپ جو کام لگائیں گے وہ یہاں آ جائے گا۔';

  @override
  String get savedTab => 'محفوظ شدہ';

  @override
  String get postedTab => 'لگائے ہوئے';

  @override
  String get savedJobGone => 'آپ کا محفوظ کیا ہوا ایک کام اب موجود نہیں۔';

  @override
  String get onboardWelcomeTitle => 'قریبی کام، آسان طریقے سے';

  @override
  String get onboardWelcomeBody =>
      'ٹرسٹ ہائر آپ کے قریب ہونے والے کام نقشے پر دکھاتی ہے۔ نہ اکاؤنٹ چاہیے، نہ کوئی فارم بھرنا ہے۔';

  @override
  String get onboardVoiceTitle => 'لکھنے کے بجائے بولیں';

  @override
  String get onboardVoiceBody =>
      'آواز کا پیغام، تصویر یا چند لفظ — کام لگانے کے لیے ان میں سے ایک ہی کافی ہے۔ فارم بھرنے کی ضرورت کبھی نہیں۔';

  @override
  String get onboardLocationTitle => 'آپ کے قریب کا کام';

  @override
  String get onboardLocationBody =>
      'اگر آپ اپنی جگہ بتائیں تو کام قربت کے حساب سے ترتیب دیے جاتے ہیں۔ آپ منع بھی کر سکتے ہیں اور پھر بھی سب کچھ استعمال کر سکتے ہیں — بس نقشہ خود ہلا لیں۔';

  @override
  String get onboardPrivacyNote =>
      'جب تک لوگ پیشکش دے رہے ہیں، آپ کی ٹھیک جگہ چھپی رہتی ہے۔ یہ صرف اُس شخص کو دی جاتی ہے جسے آپ منتخب کریں۔';

  @override
  String get onboardNext => 'آگے';

  @override
  String get onboardSkip => 'چھوڑ دیں';

  @override
  String get onboardAllowLocation => 'میری جگہ بتائیں';

  @override
  String get onboardNotNow => 'ابھی نہیں';

  @override
  String onboardStepOf(int step, int total) {
    return '$total میں سے $step قدم';
  }

  @override
  String get showIntroAgain => 'تعارف دوبارہ دکھائیں';

  @override
  String get introReset => 'اگلی بار ایپ کھولنے پر تعارف دکھایا جائے گا۔';

  @override
  String get tagPlumbing => 'پلمبنگ';

  @override
  String get tagElectrical => 'بجلی کا کام';

  @override
  String get tagPainting => 'رنگ و روغن';

  @override
  String get tagCarpentry => 'لکڑی کا کام';

  @override
  String get tagMasonry => 'راج مستری';

  @override
  String get tagConstruction => 'تعمیراتی کام';

  @override
  String get tagApplianceRepair => 'آلات کی مرمت';

  @override
  String get tagCleaning => 'صفائی';

  @override
  String get tagMoving => 'سامان کی منتقلی';

  @override
  String get tagDriving => 'ڈرائیونگ';

  @override
  String get tagGardening => 'باغبانی';

  @override
  String get tagTailoring => 'سلائی';

  @override
  String get tagCooking => 'کھانا پکانا';

  @override
  String get tagTutoring => 'پڑھائی';

  @override
  String get tagSecurity => 'حفاظت';

  @override
  String get tagLegal => 'قانونی مشورہ';

  @override
  String get tagMedical => 'طبی';

  @override
  String get tagBeauty => 'بناؤ سنگھار';

  @override
  String get tagMisc => 'عام کام';

  @override
  String get fieldTags => 'کام کی قسم';

  @override
  String get tagsHelp =>
      '1 سے 3 چنیں۔ اسی سے طے ہوتا ہے کہ آپ کا کام کون دیکھے گا۔';

  @override
  String get tagsRequired => 'کم از کم ایک قسم چنیں۔';

  @override
  String get roleWorker => 'کام کی تلاش میں';

  @override
  String get roleHirer => 'کسی کو کام دینا ہے';

  @override
  String get myTrades => 'میرے کام';

  @override
  String get myTradesHelp =>
      'آپ کو عام کام خودبخود دکھتے ہیں۔ اپنا کام شامل کریں تو وہ بھی دکھنے لگیں گے۔';

  @override
  String get whatBringsYouHere => 'آپ یہاں کس لیے آئے ہیں';

  @override
  String get roleWorkerHelp =>
      'آپ کو اپنے قریب وہ کام نظر آئیں گے جو آپ کے ہنر سے ملتے ہیں۔';

  @override
  String get roleHirerHelp => 'آپ کام پوسٹ کرتے ہیں اور کرنے والا چنتے ہیں۔';

  @override
  String get generalWorkAlwaysOn =>
      'عام کام ہمیشہ آن رہتا ہے، تاکہ کوئی کام آپ سے نہ چھوٹے۔';

  @override
  String tradeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'عام کام اور $count ہنر',
      one: 'عام کام اور 1 ہنر',
      zero: 'صرف عام کام',
    );
    return '$_temp0';
  }

  @override
  String get noJobsForTrades => 'آپ کے ہنر کے لیے یہاں کچھ نہیں';

  @override
  String get noJobsForTradesHelp =>
      'کام آپ تک تبھی پہنچتا ہے جب وہ آپ کے کسی ہنر سے ملے۔ مزید دیکھنے کے لیے ہنر شامل کریں۔';

  @override
  String get addATrade => 'ہنر شامل کریں';

  @override
  String get navActivity => 'سرگرمی';

  @override
  String get navProfile => 'پروفائل';

  @override
  String get audioOnlyJob => 'صرف آواز میں بتایا گیا';

  @override
  String get audioOnlyJobHelp =>
      'اس کام کی کوئی تحریری تفصیل نہیں۔ اگر آپ آواز نہیں سن سکتے تو پوسٹ کرنے والے سے پوچھ لیں۔';

  @override
  String get addWordsForVoiceNote =>
      'کچھ لوگ آواز کا پیغام نہیں سن سکتے۔ یہاں چند الفاظ لکھنے سے وہ آپ کا کام ڈھونڈ سکیں گے۔';

  @override
  String get jobsNearby => 'اس نقشے پر کام';

  @override
  String get openDetails => 'تفصیل کھولیں';

  @override
  String get fieldStartingFare => 'ابتدائی کرایہ';

  @override
  String get startingFareHelp =>
      'ضروری نہیں۔ یہ صرف شروعات ہے، قیمت نہیں — کام کرنے والے اپنی پیشکش دیں گے۔';

  @override
  String get fareHint => 'روپے 2,000';

  @override
  String rupees(String amount) {
    return 'روپے $amount';
  }

  @override
  String startsAt(String amount) {
    return 'شروع $amount سے';
  }

  @override
  String agreedAt(String amount) {
    return 'طے شدہ $amount';
  }

  @override
  String get offerAFare => 'اپنی قیمت بتائیں';

  @override
  String get changeMyOffer => 'اپنی پیشکش بدلیں';

  @override
  String yourOffer(String fare) {
    return 'آپ نے $fare کی پیشکش کی';
  }

  @override
  String get sendOffer => 'پیشکش بھیجیں';

  @override
  String get withdrawOffer => 'واپس لیں';

  @override
  String get offerMessageHint => 'اگر کچھ بتانا ہو تو لکھیں (ضروری نہیں)';

  @override
  String get fareMustBePositive => 'صفر سے زیادہ رقم لکھیں۔';

  @override
  String get fareLooksTooHigh => 'یہ غلطی لگتی ہے۔ رقم دوبارہ دیکھ لیں۔';

  @override
  String get offersOnThisJob => 'پیشکشیں';

  @override
  String offerCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count پیشکشیں',
      one: '1 پیشکش',
      zero: 'ابھی کوئی پیشکش نہیں',
    );
    return '$_temp0';
  }

  @override
  String get noOffersYet =>
      'ابھی کسی نے پیشکش نہیں دی۔ آس پاس کے وہ لوگ جو یہ کام کرتے ہیں، اسے دیکھیں گے۔';

  @override
  String get chooseThisWorker => 'منتخب کریں';

  @override
  String get chosen => 'منتخب';

  @override
  String get notChosen => 'منتخب نہیں';

  @override
  String get fareLocked =>
      'منتخب کرنے کے بعد کرایہ طے ہو جائے گا۔ پھر اسے بدلا نہیں جا سکتا۔';

  @override
  String confirmChoose(String amount) {
    return 'اس شخص کو $amount پر منتخب کریں؟';
  }

  @override
  String get cannotBidOwnJob => 'یہ آپ کا اپنا کام ہے۔';

  @override
  String get cannotBidAccepted => 'یہ کام کسی کو دیا جا چکا ہے۔';

  @override
  String get offerWithdrawn => 'واپس لے لی';

  @override
  String get cancel => 'منسوخ کریں';

  @override
  String get statusOpen => 'پیشکشیں لی جا رہی ہیں';

  @override
  String get statusAccepted => 'کام کرنے والا منتخب';

  @override
  String get statusInProgress => 'کام جاری ہے';

  @override
  String get statusCompleted => 'مکمل';

  @override
  String get statusCancelled => 'منسوخ';

  @override
  String get statusExpired => 'اب فہرست میں نہیں';

  @override
  String get confirmArrival => 'وہ پہنچ گئے ہیں';

  @override
  String get markComplete => 'کام مکمل ہو گیا';

  @override
  String get cancelJob => 'یہ کام منسوخ کریں';

  @override
  String get cancelJobExplanation =>
      'دوسرے شخص کو بتا دیا جائے گا۔ یہ واپس نہیں ہو سکتا۔';

  @override
  String get exactLocationShown =>
      'یہ ٹھیک جگہ ہے، کیونکہ آپ دونوں مل کر کام کر رہے ہیں۔';

  @override
  String get jobFinished => 'یہ کام مکمل ہو چکا ہے۔';

  @override
  String get jobCalledOff => 'یہ کام منسوخ کر دیا گیا تھا۔';

  @override
  String get jobExpired => 'کوئی منتخب نہیں ہوا، اس لیے یہ اب فہرست میں نہیں۔';

  @override
  String get navWallet => 'بٹوہ';

  @override
  String get walletBalance => 'بیلنس';

  @override
  String get walletTopUp => 'ٹوکن ڈالے';

  @override
  String get walletCommission => 'کمیشن';

  @override
  String get walletFirstJobCredit => 'پہلے کام کی رعایت';

  @override
  String get walletLoyaltyBonus => 'وفاداری بونس';

  @override
  String get walletCancellationPenalty => 'منسوخی کی کٹوتی';

  @override
  String get walletExplanation =>
      'کام مکمل ہونے پر ٹرسٹ ہائر طے شدہ کرائے کا 5% لیتا ہے۔ ٹوکن اصلی پیسے نہیں ہیں۔';

  @override
  String walletInDebt(String amount) {
    return 'آپ پر $amount واجب ہیں۔ اکاؤنٹ رکنے سے پہلے آپ ایک اور کام لے سکتے ہیں۔';
  }

  @override
  String get walletLocked =>
      'جب تک آپ واجبات ادا نہیں کرتے، آپ کا اکاؤنٹ رکا ہوا ہے۔ کام دوبارہ شروع کرنے کے لیے ٹوکن ڈالیں۔';

  @override
  String get walletEmpty =>
      'ابھی کچھ نہیں ہوا۔ آپ کے پہلے کام کا کمیشن یہاں نظر آئے گا۔';

  @override
  String get topUpTitle => 'ٹوکن شامل کریں';

  @override
  String get topUpNotReal =>
      'یہ صرف نمونہ ہے۔ کوئی اصلی رقم نہیں لی جاتی اور نہ کارڈ کی تفصیل مانگی جاتی ہے۔';

  @override
  String topUpConfirm(String amount) {
    return '$amount شامل کریں';
  }

  @override
  String topUpDone(String amount) {
    return '$amount آپ کے بٹوے میں شامل ہو گئے۔';
  }

  @override
  String loyaltyProgress(String amount) {
    return 'مزید $amount ڈالنے پر 1,000 ٹوکن بونس ملے گا۔';
  }

  @override
  String firstJobCreditWaiting(String amount) {
    return 'آپ کے پہلے کام کا کمیشن $amount تک معاف ہے۔';
  }

  @override
  String get rateThisJob => 'کام کیسا رہا؟';

  @override
  String get rateWorker => 'کام کرنے والے کو درجہ دیں';

  @override
  String get rateHirer => 'کام دینے والے کو درجہ دیں';

  @override
  String get rateHirerPrivate =>
      'یہ نہ اُنہیں دکھایا جاتا ہے نہ کسی اور کو۔ اس سے ہمیں مسئلہ کرنے والوں کا پتا چلتا ہے۔';

  @override
  String get rateWorkerPublic => 'یہ اُن کے پروفائل پر دکھایا جاتا ہے۔';

  @override
  String get rateNoteHint => 'کچھ بتانا ہو تو لکھیں (ضروری نہیں)';

  @override
  String get sendRating => 'بھیجیں';

  @override
  String get ratingThanks => 'شکریہ۔';

  @override
  String starsChosen(int count) {
    return '5 میں سے $count';
  }

  @override
  String get alreadyRated => 'آپ اس کام کو درجہ دے چکے ہیں۔';

  @override
  String get workerStanding => 'اُن کا ریکارڈ';

  @override
  String jobsCompleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کام مکمل',
      one: '1 کام مکمل',
      zero: 'ابھی کوئی کام مکمل نہیں',
    );
    return '$_temp0';
  }

  @override
  String averageFare(String amount) {
    return 'عام طور پر تقریباً $amount لیتے ہیں';
  }

  @override
  String get notRatedYet => 'ابھی کوئی درجہ نہیں';

  @override
  String get newToTrustHire => 'ٹرسٹ ہائر پر نئے ہیں';

  @override
  String get demoAccounts => 'ڈیمو اکاؤنٹس';

  @override
  String get demoAccountsExplain =>
      'لاگ ان بعد میں آئے گا۔ فی الحال آپ ان میں سے کوئی بھی بن سکتے ہیں — ایک کے طور پر کام لگائیں، دوسرے کے طور پر پیشکش کریں، اور ایک ہی کام کے دونوں رخ دیکھیں۔';

  @override
  String get accountYou => 'آپ';

  @override
  String get accountYouHelp => 'وہ اکاؤنٹ جس سے اس فون پر شروع ہوا';

  @override
  String get switchAccount => 'اکاؤنٹ بدلیں';

  @override
  String nowActingAs(String name) {
    return 'اب آپ $name ہیں';
  }

  @override
  String accountPostings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count کام لگائے',
      one: '1 کام لگایا',
      zero: 'کوئی کام نہیں لگایا',
    );
    return '$_temp0';
  }

  @override
  String get yourStanding => 'آپ کا ریکارڈ';

  @override
  String get offersTab => 'پیشکشیں';

  @override
  String get noOffers => 'ابھی کوئی پیشکش نہیں';

  @override
  String get noOffersMessage =>
      'کوئی کام کھولیں اور اپنی قیمت بتائیں۔ آپ کی پیشکشیں یہاں نظر آئیں گی۔';

  @override
  String get offerWaiting => 'انتظار میں';

  @override
  String get offerNotChosen => 'منتخب نہیں ہوئی';

  @override
  String get acceptBooking => 'یہ بکنگ قبول کریں';

  @override
  String get declineBooking => 'انکار کریں';

  @override
  String get declineBookingTitle => 'یہ بکنگ مسترد کریں؟';

  @override
  String get declineBookingExplanation =>
      'بک کرنے والے کو بتا دیا جائے گا اور وہ کسی اور کو بک کر سکتے ہیں۔ انکار پر کوئی رقم نہیں کٹتی۔';

  @override
  String get bookingRequest => 'براہِ راست آپ سے بک کیا گیا';

  @override
  String get bookingAwaitingWorker => 'کارکن کے قبول کرنے کا انتظار ہے';

  @override
  String get bookedFrom => 'ڈائریکٹری سے بک کیا گیا';

  @override
  String get navDirectory => 'ڈائریکٹری';

  @override
  String get directoryTitle => 'ماہر بک کریں';

  @override
  String get directoryIntro =>
      'قیمت پہلے سے طے، کوئی مول تول نہیں۔ براہِ راست بک کریں، وہ ہاں یا نہ کہیں گے۔';

  @override
  String get directoryEmpty => 'ابھی یہاں کوئی درج نہیں';

  @override
  String get directoryEmptyMessage =>
      'ڈائریکٹری میں وہ کارکن ہوتے ہیں جو مقررہ قیمت لکھتے ہیں۔ کوئی اور کام دیکھیں، یا نقشے پر کام لگا دیں۔';

  @override
  String get directoryAllWork => 'ہر قسم کا کام';

  @override
  String fromPrice(String amount) {
    return '$amount سے';
  }

  @override
  String get serviceMenu => 'وہ کیا کرتے ہیں';

  @override
  String get credentialsHeading => 'قابلیت اور تجربہ';

  @override
  String get credentialsUnverified =>
      'کارکن کا بتایا ہوا۔ ٹرسٹ ہائر نے اس کی تصدیق نہیں کی۔';

  @override
  String get serviceAreaHeading => 'وہ کہاں کام کرتے ہیں';

  @override
  String serviceAreaRadius(String distance) {
    return '$distance تک جاتے ہیں';
  }

  @override
  String get serviceAreaRemote => 'دور سے کام کرتے ہیں — آنے کی ضرورت نہیں';

  @override
  String get bookThis => 'یہ بک کریں';

  @override
  String bookingTitle(String service) {
    return '$service بک کریں';
  }

  @override
  String get bookingListPrice => 'ان کی قیمت';

  @override
  String get bookingYouPay => 'آپ دیں گے';

  @override
  String bookingSaving(String amount) {
    return 'یہاں بک کرنے پر آپ کے $amount بچے۔';
  }

  @override
  String get bookingDiscountWhy =>
      'ٹرسٹ ہائر اپنی فیس کا آدھا آپ کو واپس دیتا ہے۔ کارکن کو دونوں صورتوں میں اتنا ہی ملتا ہے۔';

  @override
  String get bookingConfirm => 'بکنگ بھیجیں';

  @override
  String bookingSent(String name) {
    return 'بکنگ بھیج دی گئی۔ $name قبول یا مسترد کریں گے۔';
  }

  @override
  String get bookingUnavailable =>
      'یہ فہرست بدل گئی ہے۔ موجودہ قیمتیں دیکھنے کے لیے دوبارہ کھولیں۔';

  @override
  String get myListing => 'میری ڈائریکٹری فہرست';

  @override
  String myListingSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خدمات درج ہیں',
      one: '1 خدمت درج ہے',
      zero: 'کچھ درج نہیں',
    );
    return '$_temp0';
  }

  @override
  String get premiumHeading => 'ڈائریکٹری میں نظر آئیں';

  @override
  String get premiumPitch =>
      'لوگ ڈائریکٹری میں ڈھونڈ کر آپ کو آپ ہی کی قیمت پر بک کرتے ہیں — بولی نہیں۔ اس کے لیے سبسکرپشن ہے۔';

  @override
  String premiumActive(String date) {
    return '$date تک درج ہیں';
  }

  @override
  String premiumDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count دن باقی',
      one: '1 دن باقی',
      zero: 'آج ختم',
    );
    return '$_temp0';
  }

  @override
  String get premiumLapsed =>
      'آپ کی فہرست ختم ہو گئی۔ پہلے سے بک شدہ کام پر اثر نہیں پڑا، اور آپ پہلے کی طرح بولی دے سکتے ہیں۔';

  @override
  String get premiumMonthly => 'ماہانہ';

  @override
  String get premiumYearly => 'سالانہ';

  @override
  String get premiumSimulated =>
      'کوئی رقم نہیں کٹتی۔ یہ نمونہ ہے اور کارڈ کی تفصیل نہیں لیتا۔';

  @override
  String get premiumStarted => 'آپ ڈائریکٹری میں آ گئے۔';

  @override
  String get addService => 'خدمت شامل کریں';

  @override
  String get serviceTitleLabel => 'یہ کیا ہے';

  @override
  String get servicePriceLabel => 'آپ کی قیمت، روپوں میں';

  @override
  String get serviceDescriptionLabel => 'اس کے بارے میں کچھ اور (اختیاری)';

  @override
  String get serviceKindLabel => 'کس قسم کا کام';

  @override
  String get saveService => 'شامل کریں';

  @override
  String get removeService => 'ہٹا دیں';

  @override
  String get noServicesYet => 'ابھی کچھ درج نہیں';

  @override
  String get noServicesYetMessage =>
      'لکھیں کہ آپ کیا کرتے ہیں اور کتنے لیتے ہیں۔ لوگ اسی قیمت پر بک کریں گے۔';

  @override
  String get addCredential => 'قابلیت شامل کریں';

  @override
  String get credentialTitleLabel => 'یہ کیا ہے';

  @override
  String get credentialIssuerLabel => 'کس نے دی (اختیاری)';

  @override
  String get credentialYearLabel => 'سال (اختیاری)';

  @override
  String get credentialKindQualification => 'قابلیت';

  @override
  String get credentialKindCertification => 'سرٹیفکیٹ';

  @override
  String get credentialKindExperience => 'تجربہ';

  @override
  String get credentialKindMembership => 'رکنیت';

  @override
  String get howFarYouTravel => 'آپ کتنی دور جاتے ہیں';

  @override
  String get remoteOnlyLabel => 'میں دور سے کام کرتا ہوں، سفر نہیں';

  @override
  String get listingNeedsService =>
      'لوگوں کے ڈھونڈنے سے پہلے کم از کم ایک خدمت شامل کریں۔';

  @override
  String get someone => 'کوئی';

  @override
  String get bookingWhatNext =>
      'وہ قبول یا مسترد کریں گے۔ دونوں صورتوں میں کوئی رقم نہیں کٹتی۔';

  @override
  String get walletAdminAdjustment => 'ٹرسٹ ہائر کی طرف سے درستی';

  @override
  String get adminPanel => 'ایڈمن';

  @override
  String adminSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count چیزیں باقی',
      one: '1 چیز باقی',
      zero: 'کچھ باقی نہیں',
    );
    return '$_temp0';
  }

  @override
  String get adminTabUsers => 'صارفین';

  @override
  String get adminTabDisputes => 'تنازعات';

  @override
  String get adminTabJobs => 'کام';

  @override
  String get adminTabLog => 'ریکارڈ';

  @override
  String get adminQueueEmpty => 'دیکھنے کے لیے کچھ نہیں';

  @override
  String get adminQueueEmptyMessage =>
      'نئے اکاؤنٹ یہاں آتے ہیں جب کوئی رجسٹر کرے۔';

  @override
  String get adminApprove => 'منظور کریں';

  @override
  String get adminSuspend => 'معطل کریں';

  @override
  String get adminReinstate => 'بحال کریں';

  @override
  String get statusPending => 'انتظار میں';

  @override
  String get statusApproved => 'منظور شدہ';

  @override
  String get statusSuspended => 'معطل';

  @override
  String get signalCnicOnFile => 'شناختی کارڈ موجود';

  @override
  String get signalCnicMissing => 'شناختی کارڈ نہیں';

  @override
  String get signalCnicShape => 'نمبر درست لگتا ہے';

  @override
  String get signalPhoneVerified => 'فون تصدیق شدہ';

  @override
  String get signalPhoneUnverified => 'فون کی تصدیق نہیں';

  @override
  String get signalSimMismatch => 'سم کا نام شناختی کارڈ سے نہیں ملتا';

  @override
  String get signalCaveat =>
      'یہ صرف امکان کی جانچ ہے، شناخت کی تصدیق نہیں۔ ٹرسٹ ہائر کسی سرکاری ڈیٹابیس میں نہیں دیکھتا۔';

  @override
  String get simMismatchCaveat =>
      'اکثر گھر کے کسی فرد کی سم ہوتی ہے۔ فیصلے سے پہلے دیکھ لیں۔';

  @override
  String get adminOpenCnic => 'شناختی کارڈ کھولیں';

  @override
  String get adminCnicLocked =>
      'شناختی کارڈ صرف اُس وقت کھل سکتا ہے جب اس شخص کے بارے میں کوئی تنازع کھلا ہو۔';

  @override
  String get adminCnicOpened => 'کھول دیا گیا۔ یہ ریکارڈ میں درج ہو گیا ہے۔';

  @override
  String get cnicNumberLabel => 'درج نمبر';

  @override
  String get cnicNameLabel => 'کارڈ پر نام';

  @override
  String get cnicNoPhoto => 'نمونے کے ساتھ کوئی تصویر نہیں بھیجی جاتی۔';

  @override
  String get adminNoDisputes => 'کوئی تنازع نہیں';

  @override
  String get adminNoDisputesMessage =>
      'تنازع کسی کام کے خلاف اٹھایا جاتا ہے۔ یہی شناختی کارڈ کھولنے کی واحد وجہ بھی ہے۔';

  @override
  String disputeAbout(String name) {
    return '$name کے بارے میں';
  }

  @override
  String disputeRaisedBy(String name) {
    return '$name نے اٹھایا';
  }

  @override
  String get disputeOpen => 'کھلا';

  @override
  String get disputeClosed => 'بند';

  @override
  String get adminCloseDispute => 'بند کریں';

  @override
  String get adminAdjustWallet => 'بیلنس درست کریں';

  @override
  String get adminUnlockWallet => 'اکاؤنٹ کھولیں';

  @override
  String adminWalletLocked(String amount) {
    return 'بند ہے — $amount واجب الادا';
  }

  @override
  String adminWalletBalance(String amount) {
    return 'بیلنس $amount';
  }

  @override
  String get adminNoteLabel => 'وجہ (ریکارڈ میں درج ہوگی)';

  @override
  String get adminNoteRequired =>
      'درستی کے لیے وجہ ضروری ہے۔ اسی سے اس کا جائزہ لیا جا سکتا ہے۔';

  @override
  String get adminApply => 'کر دیں';

  @override
  String get adminAmountLabel => 'کتنے ٹوکن، جمع یا منفی';

  @override
  String get adminLogEmpty => 'ابھی کچھ درج نہیں';

  @override
  String get adminLogEmptyMessage =>
      'ہر ایڈمن کارروائی یہاں آتی ہے — کیا، کس کے بارے میں، کیوں اور کب۔';

  @override
  String get adminLogIntro =>
      'ہر ایڈمن کارروائی، پرانی نیچے۔ یہاں کچھ بدلا یا مٹایا نہیں جا سکتا۔';

  @override
  String get actionApproveUser => 'اکاؤنٹ منظور کیا';

  @override
  String get actionSuspendUser => 'اکاؤنٹ معطل کیا';

  @override
  String get actionReinstateUser => 'اکاؤنٹ بحال کیا';

  @override
  String get actionViewCnic => 'شناختی کارڈ کھولا';

  @override
  String get actionAdjustWallet => 'بیلنس درست کیا';

  @override
  String get actionUnlockWallet => 'اکاؤنٹ کھولا';

  @override
  String get actionCancelJob => 'کام منسوخ کیا';

  @override
  String get actionCloseDispute => 'تنازع بند کیا';

  @override
  String get adminJobsIntro =>
      'پلیٹ فارم کے سارے کام، نئے پہلے، اپنی پیشکشوں کے ساتھ۔';

  @override
  String adminOffersOn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count پیشکشیں',
      one: '1 پیشکش',
      zero: 'کوئی پیشکش نہیں',
    );
    return '$_temp0';
  }

  @override
  String get accountStaffHelp => 'ٹرسٹ ہائر کا اپنا اکاؤنٹ — ایڈمن پینل';

  @override
  String get adminPanelTile => 'منظوریاں، تنازعات اور ریکارڈ';

  @override
  String get verification => 'تصدیق';

  @override
  String get verificationTile => 'شناختی کارڈ اور فون';

  @override
  String verificationSubtitle(int done) {
    String _temp0 = intl.Intl.pluralLogic(
      done,
      locale: localeName,
      other: 'تینوں مرحلے مکمل',
      two: '3 میں سے 2 مرحلے مکمل',
      one: '3 میں سے 1 مرحلہ مکمل',
      zero: 'ابھی کچھ جمع نہیں کرایا',
    );
    return '$_temp0';
  }

  @override
  String get verificationIntro =>
      'دو چیزیں، اور ان میں سے کوئی بھی شناخت کی تصدیق نہیں۔ ٹرسٹ ہائر صرف یہ دیکھتا ہے کہ شناختی نمبر کی ساخت درست ہے اور فون کوڈ کا جواب دیتا ہے۔ کسی کا ریکارڈ نہیں دیکھا جاتا۔';

  @override
  String get verificationWhyBother =>
      'کام دینے والے دیکھ سکتے ہیں کہ کارکن نے یہ مرحلہ کیا ہے یا نہیں۔ ایپ استعمال کرنے کے لیے یہ ضروری نہیں، اور نہ کرنے سے آپ کے کام چھپتے نہیں۔';

  @override
  String get verifyCnicHeading => 'آپ کا شناختی کارڈ';

  @override
  String get verifyCnicNumber => 'شناختی کارڈ نمبر';

  @override
  String get verifyCnicHint => '13 ہندسے، ڈیش کے ساتھ یا بغیر';

  @override
  String get verifyNameOnCard => 'نام، بالکل جیسے کارڈ پر لکھا ہے';

  @override
  String get verifyDateOfBirth => 'تاریخِ پیدائش';

  @override
  String get verifyChooseDate => 'منتخب کریں';

  @override
  String get verifyCnicPhoto => 'کارڈ کی تصویر';

  @override
  String get verifyCnicPhotoNote =>
      'اس ڈیمو میں کوئی تصویر اپ لوڈ نہیں ہوتی۔ یہ مرحلہ اس لیے موجود ہے کہ اصل ایپ میں تصویر محفوظ ہوتی ہے، اور اسے چھپانا کسی اور ایپ کی تصویر دکھانا ہوتا۔';

  @override
  String get verifyCnicSubmit => 'شناختی کارڈ جمع کریں';

  @override
  String get verifyCnicBadNumber => 'یہ 13 ہندسے نہیں ہیں۔ کچھ محفوظ نہیں ہوا۔';

  @override
  String get verifyCnicDone => 'شناختی کارڈ جمع ہو گیا';

  @override
  String verifyCnicOnFile(String date) {
    return '$date سے ریکارڈ میں';
  }

  @override
  String verifyCnicMasked(String masked) {
    return 'اس طرح محفوظ: $masked';
  }

  @override
  String get verifyCnicMaskExplain =>
      'صرف اتنا رکھا جاتا ہے۔ پورا نمبر اس اسکرین سے آگے نہیں جاتا — ایپ کو اس کی ضرورت نہیں، اور بلا وجہ قومی شناختی نمبر رکھنا مناسب نہیں۔';

  @override
  String get verifyCnicNotPlausible =>
      'کارڈ ریکارڈ میں ہے، مگر خودکار جانچ تصدیق نہ کر سکی۔ کوئی شخص خود دیکھے گا۔';

  @override
  String get verifyCnicPlausible =>
      'نمبر کی ساخت درست ہے، اور کارڈ پر نام اور تاریخِ پیدائش موجود ہیں۔';

  @override
  String get verifyPhoneHeading => 'آپ کا فون';

  @override
  String get verifyPhoneNumber => 'موبائل نمبر';

  @override
  String get verifyPhoneHint => '03xx xxxxxxx';

  @override
  String get verifyPhoneBad => 'یہ پاکستانی موبائل نمبر نہیں ہے۔';

  @override
  String get verifySendCode => 'مجھے کوڈ بھیجیں';

  @override
  String get verifyResendCode => 'دوبارہ بھیجیں';

  @override
  String verifyResendIn(int seconds) {
    return '$seconds سیکنڈ بعد دوبارہ بھیجیں';
  }

  @override
  String get verifyCodeLabel => '6 ہندسوں کا کوڈ';

  @override
  String get verifyCodeSubmit => 'تصدیق کریں';

  @override
  String verifyCodeSentTo(String phone) {
    return '$phone پر بھیجا گیا';
  }

  @override
  String verifyCodeWrong(int left) {
    String _temp0 = intl.Intl.pluralLogic(
      left,
      locale: localeName,
      other: '$left کوششیں باقی',
      one: '1 کوشش باقی',
    );
    return 'یہ کوڈ درست نہیں۔ $_temp0';
  }

  @override
  String get verifyCodeExpired => 'اس کوڈ کی مدت ختم ہو گئی۔ نیا منگوائیں۔';

  @override
  String get verifyCodeSpent => 'بہت زیادہ کوششیں۔ نیا کوڈ منگوائیں۔';

  @override
  String get verifyPhoneDone => 'فون کی تصدیق ہو گئی';

  @override
  String verifyPhoneConfirmedOn(String date) {
    return '$date کو تصدیق ہوئی';
  }

  @override
  String get verifyDemoSms =>
      'اس ڈیمو میں پیغام ایس ایم ایس کے بجائے یہاں دکھایا جاتا ہے';

  @override
  String get verifyDemoSmsWhy =>
      'ابھی کوئی سرور نہیں جہاں سے بھیجا جائے، اس لیے کچھ ڈیوائس سے باہر نہیں جاتا۔ باقی سب کچھ — مدت، کوششیں، دوبارہ منگوانے سے پہلے انتظار — اصل ہے۔';

  @override
  String get verifySimHeading => 'سِم پر نام';

  @override
  String get verifySimMatched =>
      'آپ کے کارڈ کا نام اس اکاؤنٹ کے نام سے ملتا ہے۔';

  @override
  String get verifySimFlagged =>
      'آپ کے کارڈ کا نام اس اکاؤنٹ کے نام سے نہیں ملتا۔ کوئی شخص اسے دیکھے گا — یہ انکار نہیں، اور گھر کے کسی فرد کی سِم استعمال کرنا اس کی عام وجہ ہے۔';

  @override
  String get verifySimNotWired =>
      'اصل جانچ میں نیٹ ورک سے پوچھا جاتا ہے کہ نمبر کس کے نام رجسٹرڈ ہے۔ یہاں وہ سہولت موجود نہیں، اس لیے آپ کے اکاؤنٹ کے نام سے موازنہ کیا جاتا ہے۔';

  @override
  String get verifyLimitNoLookup =>
      'کسی نے نادرا سے نہیں پوچھا کہ یہ کارڈ موجود ہے یا نہیں۔ یہ جانچ دائرۂ کار سے باہر ہے۔';

  @override
  String get verifyLimitPhotoUnreviewed =>
      'آپ کی تصویر نہیں دیکھی گئی، اور اُس وقت تک نہیں دیکھی جائے گی جب تک آپ کے بارے میں کوئی تنازع نہ اٹھے۔';

  @override
  String get verifyLimitSimFlag =>
      'نام کا فرق کسی شخص کے دیکھنے کی وجہ ہے، کسی بات کا ثبوت نہیں۔';

  @override
  String get verifyStatusPending => 'جائزے کا انتظار';

  @override
  String get verifyStatusApproved => 'منظور شدہ';

  @override
  String get verifyStatusSuspended => 'معطل';
}
