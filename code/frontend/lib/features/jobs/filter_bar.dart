import 'package:flutter/material.dart';

import '../../core/tokens.dart';
import '../../models/job_tag.dart';
import 'job_filter.dart';
import 'job_filter_controller.dart';
import '../../l10n/app_localizations.dart';

/// Quick filters: the two the sprint plan names, plus a way into the rest.
///
/// One tap for the common cases, nothing hidden behind a menu.
class QuickFilterBar extends StatelessWidget {
  const QuickFilterBar({
    super.key,
    required this.controller,
    this.scrollable = true,
  });

  final JobFilterController controller;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final filter = controller.filter;

    final chips = <Widget>[
      _FilterChip(
        label: TimeFilter.today.label(strings),
        icon: Icons.today_outlined,
        selected: filter.time == TimeFilter.today,
        onTap: controller.toggleToday,
      ),
      _FilterChip(
        label: DistanceFilter.nearMe.label(strings),
        icon: Icons.near_me_outlined,
        selected: filter.distance == DistanceFilter.nearMe,
        onTap: controller.toggleNearMe,
      ),
      _FilterChip(
        label: strings.voiceNote,
        icon: Icons.mic_none,
        selected: filter.withVoiceNote,
        onTap: () => controller.setWithVoiceNote(!filter.withVoiceNote),
      ),
      _FilterChip(
        label: strings.photos,
        icon: Icons.photo_library_outlined,
        selected: filter.withPhotos,
        onTap: () => controller.setWithPhotos(!filter.withPhotos),
      ),
      _FilterChip(
        label: strings.more,
        icon: Icons.tune,
        selected:
            (filter.time != TimeFilter.any &&
                filter.time != TimeFilter.today) ||
            (filter.distance != DistanceFilter.any &&
                filter.distance != DistanceFilter.nearMe) ||
            filter.tags.isNotEmpty,
        onTap: () => FilterSheet.open(context, controller),
      ),
      if (controller.isActive)
        _FilterChip(
          label: strings.clear,
          icon: Icons.close,
          selected: false,
          onTap: controller.clear,
        ),
    ];

    if (!scrollable) {
      return Wrap(
        spacing: BrandSizing.spaceSm,
        runSpacing: BrandSizing.spaceSm,
        children: chips,
      );
    }

    return SizedBox(
      height: BrandSizing.touchTargetMinimum,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: BrandSizing.spaceMd),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: BrandSizing.spaceSm),
        itemBuilder: (_, index) => Center(child: chips[index]),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Selection carries a filled background *and* a tick, so colour is never
    // the only signal (section 29).
    final foreground = selected
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
        borderRadius: BrandRadius.mediumAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: BrandRadius.mediumAll,
          child: Container(
            height: BrandSizing.touchTargetMinimum,
            padding: const EdgeInsets.symmetric(
              horizontal: BrandSizing.spaceSm + 4,
            ),
            decoration: BoxDecoration(
              borderRadius: BrandRadius.mediumAll,
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? Icons.check : icon,
                  size: 16,
                  color: foreground,
                ),
                const SizedBox(width: BrandSizing.spaceXs + 2),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The full set of filters, in a bottom sheet.
class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key, required this.controller});

  final JobFilterController controller;

  static Future<void> open(
    BuildContext context,
    JobFilterController controller,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FilterSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final filter = controller.filter;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            BrandSizing.spaceMd,
            BrandSizing.spaceSm,
            BrandSizing.spaceMd,
            BrandSizing.spaceXl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(strings.findWork, style: theme.textTheme.headlineMedium),
              const SizedBox(height: BrandSizing.spaceLg),

              Text(strings.detailWhen, style: theme.textTheme.titleMedium),
              const SizedBox(height: BrandSizing.spaceSm),
              Wrap(
                spacing: BrandSizing.spaceSm,
                runSpacing: BrandSizing.spaceSm,
                children: [
                  for (final option in TimeFilter.values)
                    _FilterChip(
                      label: option.label(strings),
                      icon: Icons.schedule,
                      selected: filter.time == option,
                      onTap: () => controller.setTime(option),
                    ),
                ],
              ),

              const SizedBox(height: BrandSizing.spaceLg),
              Text(strings.filterHowFar, style: theme.textTheme.titleMedium),
              const SizedBox(height: BrandSizing.spaceSm),
              Wrap(
                spacing: BrandSizing.spaceSm,
                runSpacing: BrandSizing.spaceSm,
                children: [
                  for (final option in DistanceFilter.values)
                    _FilterChip(
                      label: option.label(strings),
                      icon: Icons.near_me_outlined,
                      selected: filter.distance == option,
                      onTap: () => controller.setDistance(option),
                    ),
                ],
              ),

              const SizedBox(height: BrandSizing.spaceLg),
              Text(strings.filterIncludes, style: theme.textTheme.titleMedium),
              const SizedBox(height: BrandSizing.spaceSm),
              Wrap(
                spacing: BrandSizing.spaceSm,
                runSpacing: BrandSizing.spaceSm,
                children: [
                  _FilterChip(
                    label: strings.voiceNote,
                    icon: Icons.mic_none,
                    selected: filter.withVoiceNote,
                    onTap: () =>
                        controller.setWithVoiceNote(!filter.withVoiceNote),
                  ),
                  _FilterChip(
                    label: strings.photos,
                    icon: Icons.photo_library_outlined,
                    selected: filter.withPhotos,
                    onTap: () => controller.setWithPhotos(!filter.withPhotos),
                  ),
                ],
              ),

              const SizedBox(height: BrandSizing.spaceLg),
              Text(
                strings.detailKindOfWork,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: BrandSizing.spaceXs),
              Text(
                // Says the quiet part: this one does hide untyped jobs.
                strings.filterKindWarning,
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: BrandSizing.spaceSm),
              Wrap(
                spacing: BrandSizing.spaceSm,
                runSpacing: BrandSizing.spaceSm,
                children: [
                  for (final tag in JobTag.values)
                    _FilterChip(
                      label: tag.label(strings),
                      icon: tag.icon,
                      selected: filter.tags.contains(tag),
                      onTap: () => controller.toggleTag(tag),
                    ),
                ],
              ),

              const SizedBox(height: BrandSizing.spaceXl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.clear,
                      child: Text(strings.clearAll),
                    ),
                  ),
                  const SizedBox(width: BrandSizing.spaceMd),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(strings.showJobs),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The search field. Typing is the last resort in this product, so it sits
/// alongside the chips rather than above them.
class JobSearchField extends StatefulWidget {
  const JobSearchField({super.key, required this.controller});

  final JobFilterController controller;

  @override
  State<JobSearchField> createState() => _JobSearchFieldState();
}

class _JobSearchFieldState extends State<JobSearchField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.controller.filter.query,
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return TextField(
      controller: _text,
      onChanged: widget.controller.setQuery,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: strings.searchJobs,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: widget.controller.filter.query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: strings.clearSearch,
                onPressed: () {
                  _text.clear();
                  widget.controller.setQuery('');
                },
              ),
      ),
    );
  }
}
