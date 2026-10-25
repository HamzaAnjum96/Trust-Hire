import '../../models/job_tag.dart';

/// What somebody asking the assistant is after.
enum AssistantIntent {
  /// Work to do: "painting jobs near me", "kaam chahiye".
  jobs,

  /// Somebody to do it: "who can fix wiring?", "plumber chahiye".
  workers,

  /// Neither, or nothing the app can tell. Answered with what the assistant
  /// can do, never with a guess.
  unclear,
}

class AssistantQuery {
  const AssistantQuery({
    required this.intent,
    this.tags = const {},
    this.nearMe = false,
    this.words = const [],
  });

  final AssistantIntent intent;
  final Set<JobTag> tags;
  final bool nearMe;

  /// What is left once the trades and the filler are taken out — a place
  /// name, usually. Matched loosely against titles, areas and headlines.
  final List<String> words;
}

/// Understanding a request without a language model.
///
/// The assistant works on every device, including the ones that cannot run a
/// model — most phones, today. This is how: a word list in English, Urdu and
/// Roman Urdu, because that is how the people this app is for will type. It
/// is also the fallback whenever the model fails.
///
/// Three kinds of entry, because plain prefixes are too eager — "mali" would
/// catch Malik, "rang" range, "tap" tape:
///
/// - `paint` — the start of a word: painter, painting, paints.
/// - `=tap` — exactly that word.
/// - `washing machine`, or anything in Urdu script — that phrase anywhere.
class AssistantIntentReader {
  const AssistantIntentReader();

  static const _trade = <JobTag, List<String>>{
    JobTag.plumbing: ['plumb', 'pipe', '=tap', '=taps', 'leak', '=nal', 'nalka', 'sanitary', 'پلمبر', 'نلکا', 'پائپ'],
    JobTag.electrical: ['electric', 'wiring', '=wire', '=wires', 'socket', 'switchboard', 'bijli', 'بجلی', 'الیکٹریشن', 'وائرنگ'],
    JobTag.painting: ['paint', '=rang', 'colour', 'color', 'whitewash', 'رنگ', 'پینٹ'],
    JobTag.carpentry: ['carpent', 'wood', 'furniture', 'cupboard', '=door', '=doors', 'lakri', 'tarkhan', 'بڑھئی', 'ترکھان', 'فرنیچر'],
    JobTag.masonry: ['mason', 'brick', 'plaster', 'cement', '=tile', '=tiles', 'اینٹ', 'پلستر'],
    JobTag.construction: ['construct', 'build', 'contractor', 'renovat', 'تعمیر', 'ٹھیکیدار'],
    JobTag.applianceRepair: ['appliance', 'fridge', 'refrigerator', 'washing machine', 'microwave', '=ac', 'aircon', 'air condition', 'geyser', 'فریج', 'اے سی'],
    JobTag.cleaning: ['clean', '=maid', 'safai', 'sweep', 'صفائی', 'ماسی'],
    JobTag.moving: ['moving', 'mover', 'shifting', 'loader', '=truck', 'samaan', 'سامان', 'شفٹ'],
    JobTag.driving: ['driv', 'chauffeur', '=car', 'ڈرائیور', 'گاڑی'],
    JobTag.gardening: ['garden', '=mali', 'lawn', 'مالی', 'باغ'],
    JobTag.tailoring: ['tailor', 'stitch', 'sewing', 'darzi', 'silai', 'درزی', 'سلائی'],
    JobTag.cooking: ['=cook', 'cooking', '=chef', 'khana', 'catering', 'bawarchi', 'باورچی', 'کھانا'],
    JobTag.tutoring: ['tutor', 'tuition', 'teach', 'ustad', 'ٹیوشن', 'استاد'],
    JobTag.security: ['guard', 'security', 'chowkidar', 'watchman', 'چوکیدار', 'گارڈ'],
    JobTag.legal: ['lawyer', 'legal', 'advocate', 'wakeel', 'wakil', 'وکیل'],
    JobTag.medical: ['nurse', 'doctor', 'medical', 'caregiver', 'نرس', 'ڈاکٹر'],
    JobTag.beauty: ['beaut', 'salon', 'barber', 'makeup', 'mehndi', '=hair', 'haircut', 'حجام', 'بیوٹی', 'مہندی'],
    JobTag.misc: ['helper', 'labour', 'labor', 'mazdoor', 'odd job', 'مزدور'],
  };

  /// A person — "who", "plumber", "kaun". Any of these and the request is
  /// for somebody to do the work.
  static const _person = [
    'who', 'someone', 'somebody', 'anyone', 'contact', 'worker', 'recommend',
    'hire', 'person', 'expert', 'specialist', 'professional', 'plumber',
    'electrician', 'painter', 'carpenter', '=mason', 'mistri', 'cleaner',
    'driver', 'gardener', 'tailor', '=cook', 'tutor', 'teacher', 'lawyer',
    'nurse', 'barber', 'karigar', '=kaun', '=kon', '=koi', 'کون', 'کوئی',
    'کاریگر', 'مستری',
  ];

  /// Work to do.
  static const _work = [
    '=job', '=jobs', '=work', 'gig', 'opening', 'vacanc', '=kaam', '=kam',
    'naukri', 'earn', 'کام', 'نوکری',
  ];

  static const _near = [
    'near', 'close by', 'around me', '=paas', 'qareeb', 'قریب', 'پاس',
  ];

  static const _filler = {
    'the', 'for', 'and', 'any', 'some', 'can', 'could', 'please', 'show',
    'tell', 'find', 'about', 'with', 'there', 'what', 'which', 'good', 'best',
    'need', 'want', 'looking', 'get', 'fix', 'does', 'chahiye', 'hai', 'hain',
    'mein', 'liye', 'kar', 'karne', 'wala', 'wali', 'today', 'now', 'here',
    'are', 'you', 'have', 'who', 'whom', 'someone', 'somebody',
  };

  static final _token = RegExp(r'[\p{L}\p{M}\p{N}]+', unicode: true);
  static final _nonAscii = RegExp(r'[^\x00-\x7F]');

  AssistantQuery read(String text, {required bool isWorker}) {
    final tokens = _token
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .toList();
    final flat = ' ${tokens.join(' ')} ';

    bool matches(String term, String token) => term.startsWith('=')
        ? token == term.substring(1)
        : token.startsWith(term);

    bool has(String term) {
      if (_nonAscii.hasMatch(term) || term.contains(' ')) {
        return flat.contains(term);
      }
      return tokens.any((token) => matches(term, token));
    }

    bool claimed(String token, List<String> terms) => terms.any(
      (term) =>
          !_nonAscii.hasMatch(term) &&
          !term.contains(' ') &&
          matches(term, token),
    );

    final tags = {
      for (final entry in _trade.entries)
        if (entry.value.any(has)) entry.key,
    };
    final person = _person.any(has);
    final work = _work.any(has);
    final nearMe = _near.any(has);

    final AssistantIntent intent;
    if (person && !work) {
      intent = AssistantIntent.workers;
    } else if (work && !person) {
      intent = AssistantIntent.jobs;
    } else if (tags.isNotEmpty || person || work) {
      // A trade with no other clue, or both clues at once: go by what this
      // person uses the app for. A worker typing "painting" wants painting
      // work; a hirer typing it wants a painter.
      intent = isWorker ? AssistantIntent.jobs : AssistantIntent.workers;
    } else {
      intent = AssistantIntent.unclear;
    }

    final words = intent == AssistantIntent.unclear
        ? const <String>[]
        : [
            for (final token in tokens)
              if (token.length > 2 &&
                  !_nonAscii.hasMatch(token) &&
                  !_filler.contains(token) &&
                  !claimed(token, _work) &&
                  !claimed(token, _near) &&
                  !claimed(token, _person) &&
                  !_trade.values.any((terms) => claimed(token, terms)))
                token,
          ];

    return AssistantQuery(
      intent: intent,
      tags: tags,
      nearMe: nearMe,
      words: words,
    );
  }
}
