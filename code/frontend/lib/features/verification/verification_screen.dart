import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/verification_controller.dart';
import '../../core/formatters.dart';
import '../../core/layout.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../models/verification.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_pill.dart';
import 'verification_rules.dart';

/// Section 2, from the side of the person being verified.
///
/// Two steps and a consequence: submit a card, confirm a phone, and — once
/// both exist — a name comparison that can disagree. **Nothing here is a
/// gate.** A worker who does none of it keeps a working app; the only thing
/// that changes is what a hirer can see about them, which is what the
/// introduction says before anything else.
///
/// Every claim on this screen is accompanied by what it does not mean. That is
/// not decoration: "verified" over a check that only confirms a number is
/// thirteen digits long is the single most misleading thing this app could
/// say, and Section 2 spends most of its length saying so.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const VerificationScreen()),
    );
  }

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _cnic = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();

  DateTime? _dateOfBirth;
  String? _cnicError;
  String? _phoneError;
  String? _codeError;

  /// Ticks while a resend cooldown is running, so the button can count down
  /// rather than being disabled with no explanation.
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    final controller = context.read<VerificationController>();
    _phone.text = controller.rules.formatPhone(controller.mine.phone);
    if (controller.hasCodeOutstanding) _startTicking();
  }

  @override
  void dispose() {
    _tick?.cancel();
    _cnic.dispose();
    _name.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startTicking() {
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      final left = context.read<VerificationController>().resendWait();
      setState(() {});
      if (left == Duration.zero) timer.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final controller = context.watch<VerificationController>();
    final mine = controller.mine;

    return Scaffold(
      appBar: AppBar(title: Text(strings.verification)),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.all(BrandSizing.spaceMd),
          children: [
            Text(strings.verificationIntro, style: theme.textTheme.bodyMedium),
            const SizedBox(height: BrandSizing.spaceSm),
            Text(
              strings.verificationWhyBother,
              style: theme.textTheme.labelSmall,
            ),
            const SizedBox(height: BrandSizing.spaceMd),
            Row(
              children: [
                StatusPill.muted(
                  context,
                  strings.verificationSubtitle(mine.stepsDone),
                ),
              ],
            ),

            const SizedBox(height: BrandSizing.spaceXl),
            Text(strings.verifyCnicHeading, style: theme.textTheme.titleLarge),
            const SizedBox(height: BrandSizing.spaceSm),
            if (mine.cnicOnFile)
              _CnicOnFile(verification: mine)
            else
              _cnicForm(context, strings, theme),

            const SizedBox(height: BrandSizing.spaceXl),
            Text(strings.verifyPhoneHeading, style: theme.textTheme.titleLarge),
            const SizedBox(height: BrandSizing.spaceSm),
            _phoneSection(context, strings, theme, controller),

            // Only once there are two names to compare. Before that there is
            // nothing to say, and a green tick for a check that has not run
            // would be the screen's first lie.
            if (mine.cnicOnFile && mine.phone != null) ...[
              const SizedBox(height: BrandSizing.spaceXl),
              Text(strings.verifySimHeading, style: theme.textTheme.titleLarge),
              const SizedBox(height: BrandSizing.spaceSm),
              // Only a check that ran gets a verdict. On an account with no
              // name to compare against there is no result, and a green tick
              // would be claiming one.
              if (controller.canCheckSimName) ...[
                NoticePanel(
                  message: mine.simNameMatches
                      ? strings.verifySimMatched
                      : strings.verifySimFlagged,
                  icon: mine.simNameMatches
                      ? Icons.check_circle_outline
                      : Icons.flag_outlined,
                  tone: mine.simNameMatches
                      ? NoticeTone.success
                      : NoticeTone.warning,
                ),
                const SizedBox(height: BrandSizing.spaceSm),
              ],
              Text(
                strings.verifySimNotWired,
                style: theme.textTheme.labelSmall,
              ),
            ],

            const SizedBox(height: BrandSizing.spaceXl),
            _Limits(limits: controller.limits),
            const SizedBox(height: BrandSizing.spaceXl),
          ],
        ),
      ),
    );
  }

  // --- The CNIC ------------------------------------------------------------

  Widget _cnicForm(BuildContext context, AppStrings strings, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _cnic,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9-]')),
            LengthLimitingTextInputFormatter(15),
          ],
          decoration: InputDecoration(
            labelText: strings.verifyCnicNumber,
            hintText: strings.verifyCnicHint,
            errorText: _cnicError,
          ),
        ),
        const SizedBox(height: BrandSizing.spaceMd),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: strings.verifyNameOnCard),
        ),
        const SizedBox(height: BrandSizing.spaceMd),
        Row(
          children: [
            Expanded(
              child: Text(
                _dateOfBirth == null
                    ? strings.verifyDateOfBirth
                    : '${strings.verifyDateOfBirth}: '
                          '${Format.day(strings, _dateOfBirth!)} '
                          '${_dateOfBirth!.year}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            TextButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(strings.verifyChooseDate),
            ),
          ],
        ),
        const SizedBox(height: BrandSizing.spaceSm),
        Text(strings.verifyCnicPhotoNote, style: theme.textTheme.labelSmall),
        const SizedBox(height: BrandSizing.spaceMd),
        FilledButton.icon(
          onPressed: _submitCnic,
          icon: const Icon(Icons.badge_outlined),
          label: Text(strings.verifyCnicSubmit),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _submitCnic() async {
    final strings = AppStrings.of(context);
    final controller = context.read<VerificationController>();

    final accepted = await controller.submitCnic(
      number: _cnic.text,
      name: _name.text,
      dateOfBirth: _dateOfBirth,
    );

    if (!mounted) return;

    setState(() {
      _cnicError = accepted ? null : strings.verifyCnicBadNumber;
    });

    if (accepted) {
      // Cleared rather than left on screen: the number is masked the moment it
      // is stored, and leaving the whole one sitting in a text field would
      // undo that for anybody who picks the phone up.
      _cnic.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.verifyCnicDone)));
    }
  }

  // --- The phone -----------------------------------------------------------

  Widget _phoneSection(
    BuildContext context,
    AppStrings strings,
    ThemeData theme,
    VerificationController controller,
  ) {
    final mine = controller.mine;
    final wait = controller.resendWait();
    final outstanding = controller.hasCodeOutstanding;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mine.phoneVerified) ...[
          Row(
            children: [
              StatusPill.good(strings.verifyPhoneDone),
              const SizedBox(width: BrandSizing.spaceSm),
              Expanded(
                child: Text(
                  controller.rules.formatPhone(mine.phone),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: BrandSizing.spaceXs),
          Text(
            strings.verifyPhoneConfirmedOn(
              Format.day(strings, mine.phoneVerifiedAt!),
            ),
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: BrandSizing.spaceMd),
        ],

        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: strings.verifyPhoneNumber,
            hintText: strings.verifyPhoneHint,
            errorText: _phoneError,
          ),
        ),
        const SizedBox(height: BrandSizing.spaceMd),
        OutlinedButton.icon(
          onPressed: wait > Duration.zero ? null : _sendCode,
          icon: const Icon(Icons.sms_outlined),
          label: Text(
            wait > Duration.zero
                ? strings.verifyResendIn(wait.inSeconds)
                : (outstanding
                      ? strings.verifyResendCode
                      : strings.verifySendCode),
          ),
        ),

        if (outstanding) ...[
          const SizedBox(height: BrandSizing.spaceLg),
          if (controller.demoMessage != null) ...[
            NoticePanel(
              message: '${strings.verifyDemoSms}\n\n'
                  '${controller.demoMessage}',
              icon: Icons.smartphone_outlined,
              tone: NoticeTone.warning,
            ),
            const SizedBox(height: BrandSizing.spaceXs),
            Text(strings.verifyDemoSmsWhy, style: theme.textTheme.labelSmall),
            const SizedBox(height: BrandSizing.spaceMd),
          ],
          Text(
            strings.verifyCodeSentTo(
              controller.rules.formatPhone(controller.challenge!.phone),
            ),
            style: theme.textTheme.labelMedium,
          ),
          const SizedBox(height: BrandSizing.spaceSm),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(VerificationRules.codeLength),
            ],
            decoration: InputDecoration(
              labelText: strings.verifyCodeLabel,
              errorText: _codeError,
            ),
          ),
          const SizedBox(height: BrandSizing.spaceMd),
          FilledButton(
            onPressed: _confirmCode,
            child: Text(strings.verifyCodeSubmit),
          ),
        ],
      ],
    );
  }

  Future<void> _sendCode() async {
    final strings = AppStrings.of(context);
    final controller = context.read<VerificationController>();

    final sent = await controller.sendCode(_phone.text);
    if (!mounted) return;

    setState(() {
      _phoneError = sent ? null : strings.verifyPhoneBad;
      _codeError = null;
    });

    if (sent) {
      _code.clear();
      _startTicking();
    }
  }

  Future<void> _confirmCode() async {
    final strings = AppStrings.of(context);
    final controller = context.read<VerificationController>();

    final result = await controller.confirmCode(_code.text);
    if (!mounted) return;

    final left =
        VerificationRules.maxAttempts - (controller.challenge?.attempts ?? 0);

    setState(() {
      _codeError = switch (result) {
        PhoneCheckResult.confirmed => null,
        PhoneCheckResult.wrong => strings.verifyCodeWrong(left),
        PhoneCheckResult.expired => strings.verifyCodeExpired,
        PhoneCheckResult.tooManyAttempts => strings.verifyCodeSpent,
        PhoneCheckResult.nothingSent => strings.verifyCodeExpired,
      };
    });

    if (result == PhoneCheckResult.confirmed) {
      _code.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(strings.verifyPhoneDone)));
    }
  }
}

/// What is on file, once something is.
///
/// Shows the mask rather than offering to re-enter the number: the app does
/// not have the whole one to show, which is the point, and a field inviting
/// somebody to type it again is a field that would need it.
class _CnicOnFile extends StatelessWidget {
  const _CnicOnFile({required this.verification});

  final Verification verification;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            StatusPill.good(strings.verifyCnicDone),
            const SizedBox(width: BrandSizing.spaceSm),
            Expanded(
              child: Text(
                strings.verifyCnicOnFile(
                  Format.day(strings, verification.cnicSubmittedAt!),
                ),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        if (verification.cnicMasked != null) ...[
          const SizedBox(height: BrandSizing.spaceSm),
          Text(
            strings.verifyCnicMasked(verification.cnicMasked!),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: BrandSizing.spaceXs),
          Text(
            strings.verifyCnicMaskExplain,
            style: theme.textTheme.labelSmall,
          ),
        ],
        const SizedBox(height: BrandSizing.spaceMd),
        NoticePanel(
          message: verification.cnicPlausible
              ? strings.verifyCnicPlausible
              : strings.verifyCnicNotPlausible,
          icon: verification.cnicPlausible
              ? Icons.check_circle_outline
              : Icons.hourglass_empty,
          tone: verification.cnicPlausible
              ? NoticeTone.success
              : NoticeTone.warning,
        ),
      ],
    );
  }
}

/// What none of this establishes.
///
/// Rendered from [VerificationRules.describeLimits] rather than written into
/// the screen, so a caveat cannot be dropped by editing the layout — the list
/// travels with the signals it qualifies.
class _Limits extends StatelessWidget {
  const _Limits({required this.limits});

  final Set<VerificationLimit> limits;

  @override
  Widget build(BuildContext context) {
    if (limits.isEmpty) return const SizedBox.shrink();

    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    String label(VerificationLimit limit) => switch (limit) {
      VerificationLimit.noGovernmentLookup => strings.verifyLimitNoLookup,
      VerificationLimit.photoUnreviewed => strings.verifyLimitPhotoUnreviewed,
      VerificationLimit.simMismatchIsNotGuilt => strings.verifyLimitSimFlag,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final limit in limits)
          Padding(
            padding: const EdgeInsets.only(bottom: BrandSizing.spaceXs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: BrandSizing.spaceSm),
                Expanded(
                  child: Text(label(limit), style: theme.textTheme.labelSmall),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
