import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ai_controller.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../services/ai/browser_model.dart';
import '../../widgets/settings_group.dart';
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

    return SettingsGroup(
      title: strings.aiSection,
      caption: ai.isRemote
          ? strings.aiRemoteExplain(ai.modelName)
          : ai.state == AiState.unsupported
          ? (ai.unsupportedReason == 'software-gpu'
                ? strings.aiUnsupportedSoftware
                : strings.aiUnsupported)
          : strings.aiExplain,
      children: [
        GroupPadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ai.modelName,
                      style: BrandType.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  pill,
                ],
              ),
              if (ai.state == AiState.loading) ...[
                const SizedBox(height: BrandSizing.spaceSm),
                LinearProgressIndicator(
                  value: ai.progress > 0 ? ai.progress : null,
                ),
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
                  onSelectionChanged: (selection) =>
                      ai.setChoice(selection.first),
                ),
                const SizedBox(height: BrandSizing.spaceXs),
                Text(
                  ai.downloaded == true
                      ? strings.aiModelDownloaded(ai.choice.label)
                      : strings.aiModelSize(
                          ai.choice.label,
                          ai.choice.downloadMb,
                        ),
                  style: theme.textTheme.labelSmall,
                ),
              ],

              // What went wrong last time, in the browser's own words — so a
              // failure can be passed on, not only seen. Selectable, to copy.
              if (ai.lastProblem case final problem?) ...[
                const SizedBox(height: BrandSizing.spaceSm),
                SelectableText(
                  strings.aiLastProblem(problem),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (ai.available && !ai.enabled)
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: Text(strings.aiTurnOn),
            onTap: () => askToTurnOnAi(context),
          ),
        if (ai.available && ai.enabled && ai.state == AiState.failed)
          ListTile(
            leading: const Icon(Icons.refresh),
            title: Text(strings.aiTryAgain),
            onTap: ai.ensureReady,
          ),
        if (ai.available && ai.enabled)
          ListTile(
            leading: const Icon(Icons.pause_circle_outline),
            title: Text(strings.aiTurnOff),
            onTap: ai.disable,
          ),
        // Gigabytes are somebody's data plan: taking them back off is offered
        // as plainly as putting them on.
        if (!ai.isRemote && ai.downloaded == true)
          ListTile(
            leading: const Icon(
              Icons.delete_outline,
              color: BrandColours.errorRed,
            ),
            title: Text(strings.aiRemoveDownload),
            onTap: ai.removeDownload,
          ),
      ],
    );
  }
}
