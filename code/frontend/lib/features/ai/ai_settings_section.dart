import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ai_controller.dart';
import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/settings_group.dart';
import '../../widgets/status_pill.dart';
import 'ai_consent.dart';

/// The AI, from the profile: what it is, where it runs, and whether it is on.
class AiSettingsSection extends StatelessWidget {
  const AiSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final ai = context.watch<AiController>();

    final pill = switch (ai.state) {
      AiState.on => StatusPill.good(context, strings.aiStatusReady),
      AiState.off ||
      AiState.unavailable => StatusPill.muted(context, strings.aiStatusOff),
    };

    return SettingsGroup(
      title: strings.aiSection,
      caption: ai.available
          ? strings.aiExplain(ai.modelName)
          : strings.aiNotInThisBuild,
      children: [
        if (ai.available)
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
                // What went wrong last time, in the words that came back, so
                // a failure can be passed on, not only seen. Selectable, to
                // copy.
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
            leading: const Icon(Icons.cloud_rounded),
            title: Text(strings.aiTurnOn),
            onTap: () => askToTurnOnAi(context),
          ),
        if (ai.available && ai.enabled)
          ListTile(
            leading: const Icon(Icons.pause_circle_outline_rounded),
            title: Text(strings.aiTurnOff),
            onTap: ai.disable,
          ),
      ],
    );
  }
}
