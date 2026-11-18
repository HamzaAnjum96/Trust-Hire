import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ai_controller.dart';
import '../../l10n/app_localizations.dart';

/// Asks before the AI is switched on — and so before anything is sent.
///
/// The AI is Trust Hire's Cloudflare Worker, so a question and the job details
/// it needs leave the device. The dialog says so, says what never does (phone
/// numbers), and that nothing is kept. It used to ask about a download of
/// hundreds of megabytes for a model that ran in the browser; that model is
/// gone (0.25).
///
/// Returns whether the AI is now on.
Future<bool> askToTurnOnAi(BuildContext context) async {
  final ai = context.read<AiController>();
  final strings = AppStrings.of(context);
  if (!ai.available) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      // Where it goes, said with a cloud — not a sparkle: the brand
      // guidelines rule those out.
      icon: const Icon(Icons.cloud_rounded),
      title: Text(strings.aiConsentTitle),
      content: Text(strings.aiConsentBody(ai.modelName)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(strings.aiConsentCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(strings.aiTurnOn),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;
  await ai.enable();
  return true;
}
