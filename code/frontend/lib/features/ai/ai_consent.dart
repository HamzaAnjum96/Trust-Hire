import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ai_controller.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';

/// Asks before the AI is switched on — and so before anything is downloaded.
///
/// Says how big the download is and that it happens once, because the people
/// this app is for pay for data by the megabyte; says nothing typed leaves
/// the device, because that is the reason to run it here at all. A model
/// already in this browser's cache costs nothing, and the dialog says that
/// instead.
///
/// Returns whether the AI is now on.
Future<bool> askToTurnOnAi(BuildContext context) async {
  final ai = context.read<AiController>();
  final strings = AppStrings.of(context);
  final size = ai.choice.downloadMb;

  final body = ai.isRemote
      ? strings.aiConsentRemoteBody(ai.modelName)
      : ai.downloaded == true
      ? strings.aiConsentBodyDownloaded(ai.modelName)
      : strings.aiConsentBody(ai.modelName, size);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BrandRadius.largeAll),
      icon: const Icon(Icons.auto_awesome_outlined),
      title: Text(strings.aiConsentTitle),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(strings.aiConsentCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            ai.isRemote || ai.downloaded == true
                ? strings.aiTurnOn
                : strings.aiConsentDownload,
          ),
        ),
      ],
    ),
  );

  if (confirmed != true) return false;
  // Not awaited: the download can take minutes, and the screens show its
  // progress from the controller rather than holding a dialog open.
  ai.enable();
  return true;
}
