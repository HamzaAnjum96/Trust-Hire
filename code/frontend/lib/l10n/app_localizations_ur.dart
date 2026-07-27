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
  String get couldNotLoadJobsShort => 'کام لوڈ نہیں ہو سکے۔ دوبارہ کوشش کریں۔';

  @override
  String get tryAgain => 'دوبارہ کوشش کریں';

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
  String get filterWhen => 'کب';

  @override
  String get filterHowFar => 'کتنی دور';

  @override
  String get filterIncludes => 'اس میں کیا ہے';

  @override
  String get filterKind => 'کام کی قسم';

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
  String get onThisDevice => 'اسی فون پر';

  @override
  String get detailWhen => 'کب';

  @override
  String get detailArea => 'علاقہ';

  @override
  String get detailPostedBy => 'لگانے والے';

  @override
  String get detailKindOfWork => 'کام کی قسم';

  @override
  String get generalAreaNotice => 'یہ عام علاقہ ہے، پورا پتہ نہیں۔';

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
  String get kindOfWorkOptional =>
      'یہ ضروری نہیں۔ قسم چننے سے آپ کا کام نقشے پر آسانی سے نظر آتا ہے۔';

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
      'عام علاقہ چنیں۔ آپ کی اصل جگہ کسی کو نہیں دکھائی جائے گی۔';

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
  String get addSomethingFirst =>
      'پہلے آواز کا پیغام، تصویر یا چھوٹا پیغام ڈالیں۔';

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
  String get typePlumbing => 'پلمبنگ';

  @override
  String get typeElectrical => 'بجلی کا کام';

  @override
  String get typePainting => 'رنگ و روغن';

  @override
  String get typeCarpentry => 'لکڑی کا کام';

  @override
  String get typeMasonry => 'راج مستری';

  @override
  String get typeConstruction => 'تعمیراتی کام';

  @override
  String get typeApplianceRepair => 'آلات کی مرمت';

  @override
  String get typeCleaning => 'صفائی';

  @override
  String get typeMoving => 'سامان کی منتقلی';

  @override
  String get typeDriving => 'ڈرائیونگ';

  @override
  String get typeGardening => 'باغبانی';

  @override
  String get typeTailoring => 'سلائی';

  @override
  String get typeCooking => 'کھانا پکانا';

  @override
  String get typeTutoring => 'پڑھائی';

  @override
  String get typeSecurity => 'حفاظت';

  @override
  String get typeOther => 'کوئی اور کام';

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
  String get save => 'محفوظ کریں';

  @override
  String get saved => 'محفوظ شدہ';

  @override
  String get saveThisJob => 'یہ کام محفوظ کریں';

  @override
  String get removeFromSaved => 'محفوظ شدہ سے ہٹائیں';

  @override
  String get jobSaved => 'محفوظ ہو گیا۔ اسے محفوظ شدہ میں دیکھیں۔';

  @override
  String get jobUnsaved => 'محفوظ شدہ سے ہٹا دیا گیا۔';

  @override
  String get navSaved => 'محفوظ شدہ';

  @override
  String get savedJobs => 'محفوظ کام';

  @override
  String get myPostings => 'میرے لگائے ہوئے کام';

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
  String savedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محفوظ',
      one: '1 محفوظ',
    );
    return '$_temp0';
  }

  @override
  String postedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count لگائے',
      one: '1 لگایا',
    );
    return '$_temp0';
  }

  @override
  String get savedJobGone => 'آپ کا محفوظ کیا ہوا ایک کام اب موجود نہیں۔';
}
