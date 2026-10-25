import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ai_controller.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai/browser_model.dart';
import '../../widgets/status_pill.dart';
import 'ai_consent.dart';

/// The AI, from the profile: what it is, whether it is on, which size, and
/// how to take the download back off this device.
class AiSettingsSection extends StatelessWidget {
  const AiSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final ai = context.watch<AiController>();

    final pill = switch (ai.state) {
      AiState.checking => StatusPill.muted(context, strings.aiStatusChecking),
      AiState.unsupported => StatusPill.muted(
        context,
        strings.aiStatusUnsupported,
      ),
      AiState.off => StatusPill.muted(context, strings.aiStatusOff),
      AiState.idle => StatusPill.good(strings.aiStatusIdle),
      AiState.loading => StatusPill.muted(
        context,
        strings.aiStatusLoading((ai.progress * 100).round()),
      ),
      AiState.ready => StatusPill.good(strings.aiStatusReady),
      AiState.failed => StatusPill.bad(strings.aiStatusFailed),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.aiSection, style: theme.textTheme.titleLarge),
        const SizedBox(height: BrandSizing.spaceXs),
        Text(
          ai.isRemote
              ? strings.aiRemoteExplain(ai.modelName)
              : ai.state == AiState.unsupported
              ? strings.aiUnsupported
              : strings.aiExplain,
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(height: BrandSizing.spaceMd),
        Align(alignment: AlignmentDirectional.centerStart, child: pill),

        if (ai.state == AiState.loading) ...[
          const SizedBox(height: BrandSizing.spaceSm),
          LinearProgressIndicator(value: ai.progress > 0 ? ai.progress : null),
        ],

        // Which size. Not offered for a remote model, which has none.
        if (!ai.isRemote && ai.available) ...[
          const SizedBox(height: BrandSizing.spaceMd),
          SegmentedButton<BrowserModelChoice>(
            segments: [
              for (final choice in BrowserModelChoice.values)
                ButtonSegment(
                  value: choice,
                  label: Text(
                    choice == BrowserModelChoice.standard
                        ? strings.aiModelStandard
                        : strings.aiModelLight,
                  ),
                ),
            ],
            selected: {ai.choice},
            onSelectionChanged: (selection) => ai.setChoice(selection.first),
          ),
          const SizedBox(height: BrandSizing.spaceXs),
          Text(
            ai.downloaded == true
                ? strings.aiModelDownloaded(ai.choice.label)
                : strings.aiModelSize(ai.choice.label, ai.choice.downloadMb),
            style: theme.textTheme.labelSmall,
          ),
        ],

        if (ai.available) ...[
          const SizedBox(height: BrandSizing.spaceMd),
          Wrap(
            spacing: BrandSizing.spaceSm,
            runSpacing: BrandSizing.spaceSm,
            children: [
              if (!ai.enabled)
                FilledButton.icon(
                  onPressed: () => askToTurnOnAi(context),
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: Text(strings.aiTurnOn),
                )
              else ...[
                if (ai.state == AiState.failed)
                  OutlinedButton.icon(
                    onPressed: ai.ensureReady,
                    icon: const Icon(Icons.refresh),
                    label: Text(strings.aiTryAgain),
                  ),
                OutlinedButton.icon(
                  onPressed: ai.disable,
                  icon: const Icon(Icons.pause_circle_outline),
                  label: Text(strings.aiTurnOff),
                ),
              ],
              if (!ai.isRemote && ai.downloaded == true)
                TextButton.icon(
                  onPressed: ai.removeDownload,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(strings.aiRemoveDownload),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
