import 'dart:convert';

import 'ai_prompts.dart';

/// What every request to a model, and every reply from one, goes through.
///
/// A language model is treated the way the backend treats a client: anything
/// it says is a claim to check, and anything people wrote is data that may
/// try to give orders. These are the checks, in one place so no feature can
/// skip one.
class AiSafety {
  const AiSafety._();

  /// The longest request a person can send. Long enough for any real question
  /// about jobs or workers; short enough that a pasted essay of instructions
  /// does not fit.
  static const maxRequestLength = 400;

  /// The longest prose a model's answer may put on screen.
  static const maxProseLength = 360;

  /// Said to every model, first — see [AiPrompts.rules]. The framing below
  /// is what it refers to.
  static const rules = AiPrompts.rules;

  /// A person's own words, made safe to show a model: control characters
  /// gone, whitespace collapsed, length capped.
  static String userText(String text) {
    final flat = text
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return flat.length <= maxRequestLength
        ? flat
        : flat.substring(0, maxRequestLength);
  }

  /// [text] marked as data. The markers are stripped from inside it first, so
  /// nothing written by a person can close the frame early.
  static String framed(String text) =>
      '<<<${text.replaceAll('<<<', '').replaceAll('>>>', '')}>>>';

  /// The first JSON object in [reply], or null. Lenient about what surrounds
  /// it — small models wrap answers in prose or code fences — and strict
  /// about what it is.
  static Map<String, Object?>? jsonObject(String reply) {
    final start = reply.indexOf('{');
    final end = reply.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final value = jsonDecode(reply.substring(start, end + 1));
      return value is Map<String, Object?> ? value : null;
    } on FormatException {
      return null;
    }
  }

  static final _link = RegExp(
    r'(https?://\S+|www\.\S+|\b[\w.-]+\.(com|pk|net|org|io|app|me)\b\S*)',
    caseSensitive: false,
  );
  static final _email = RegExp(r'\b[\w.+-]+@[\w-]+\.[\w.]+\b');

  /// Seven or more digits, allowing the spaces and dashes people put in phone
  /// numbers. Prices survive: "Rs. 12,500" has five.
  static final _phone = RegExp(r'\+?\d(?:[\s-]?\d){6,}');

  /// A model's prose, fit to put on screen: no links, no email addresses, no
  /// phone numbers — none of which this app ever needs a model to supply,
  /// and all of which are how a scam would use one — and no more than
  /// [maxProseLength] characters.
  static String prose(Object? text) {
    if (text is! String) return '';
    // Email addresses before links: the link pattern would otherwise take
    // the domain and leave "name@…" on screen.
    var clean = text
        .replaceAll(_email, '…')
        .replaceAll(_link, '…')
        .replaceAll(_phone, '…')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.length > maxProseLength) {
      clean = '${clean.substring(0, maxProseLength).trimRight()}…';
    }
    return clean;
  }

  /// The end of a sentence: a full stop, question or exclamation mark —
  /// English or Urdu — before a space or the end. Not the dot in "Rs. 2,500".
  static final _sentenceEnd = RegExp(
    r'(?<!\brs)[.!?\u06D4\u061F](?=\s|$)',
    caseSensitive: false,
  );

  /// The first [count] sentences of [text]. Asked for one or two short
  /// sentences, Qwen2.5 1.5B wrote five, and the later ones were where it
  /// started making things up.
  static String firstSentences(String text, int count) {
    var seen = 0;
    for (final end in _sentenceEnd.allMatches(text)) {
      if (++seen == count) return text.substring(0, end.end).trim();
    }
    return text;
  }

  static final _word = RegExp(r'[\p{L}\p{N}_]+', unicode: true);

  /// How many words in a row, shared with what a model was told, make a reply
  /// its instructions coming back rather than an answer. Five: "the search
  /// found" is a fair thing to say; "about what the search found, and" is
  /// the prompt.
  static const echoRun = 5;

  /// Whether [reply] repeats [told] — any [echoRun] words in a row that also
  /// appear in a row there, ignoring case and punctuation.
  ///
  /// Qwen2.5 0.5B, asked in the app who could fix wiring, searched correctly
  /// and then "answered" with two sentences of its own instructions: "one or
  /// two sentences in English about what the search found, and job_ids or
  /// worker_ids are the ids of the results you mention." A reply like that is
  /// not shown; the app's own sentence is.
  static bool echoes(String reply, String told) {
    List<String> words(String text) => [
      for (final m in _word.allMatches(text.toLowerCase())) m.group(0)!,
    ];
    final said = words(reply);
    if (said.length < echoRun) return false;
    final source = words(told);
    final runs = <String>{
      for (var i = 0; i + echoRun <= source.length; i++)
        source.sublist(i, i + echoRun).join(' '),
    };
    for (var i = 0; i + echoRun <= said.length; i++) {
      if (runs.contains(said.sublist(i, i + echoRun).join(' '))) return true;
    }
    return false;
  }

  static final _urduLetter = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]',
  );
  static final _latinLetter = RegExp('[A-Za-z]');

  /// Whether [text] is in the language of the screen — `ur` or `en` — told
  /// apart by script: more letters in Urdu's than in the Latin alphabet, or
  /// the other way round, so a name or a place in the other script does not
  /// tip it.
  ///
  /// Small models drift into English when asked for Urdu. A sentence in the
  /// wrong language is not shown; the app's own, in the right one, is.
  static bool writtenIn(String text, String languageCode) {
    final urdu = _urduLetter.allMatches(text).length;
    final latin = _latinLetter.allMatches(text).length;
    return languageCode == 'ur' ? urdu > latin : latin >= urdu;
  }

  /// The first number in a string, thousands separators and all.
  static final _number = RegExp(r'\d[\d,]*(\.\d+)?');

  /// A whole number of rupees from whatever a model wrote it as — 2500,
  /// "2,500" or "Rs. 2,500". The first number in a string is the amount: the
  /// dot after "Rs" is not a decimal point, which is how "Rs. 2,500" was once
  /// read as a quarter of a rupee.
  static int? rupees(Object? value) {
    if (value is bool) return null;
    if (value is num) return value >= 1 ? value.round() : null;
    if (value is String) {
      final match = _number.firstMatch(value);
      if (match == null) return null;
      final number = double.tryParse(match.group(0)!.replaceAll(',', ''));
      return number != null && number >= 1 ? number.round() : null;
    }
    return null;
  }
}
