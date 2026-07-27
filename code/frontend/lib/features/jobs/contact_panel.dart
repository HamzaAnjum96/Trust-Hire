import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../services/contact_launcher.dart';

/// The poster's phone number, and the two ways people actually use one.
///
/// **Hidden until asked for.** The product promises approximate locations and
/// says so on every job; showing a phone number unprompted alongside that
/// would undercut it. A deliberate tap is also a small brake on casual
/// scraping — not real protection, but the honest version of what a POC with
/// no accounts can offer, and the copy says exactly that.
///
/// Every action can fail — no dialler, no WhatsApp, a browser that blocks the
/// scheme — so the number stays on screen and the failure explains that you
/// can use it yourself.
class ContactPanel extends StatefulWidget {
  const ContactPanel({
    super.key,
    required this.number,
    this.launcher = const ContactLauncher(),
  });

  final String number;
  final ContactLauncher launcher;

  @override
  State<ContactPanel> createState() => _ContactPanelState();
}

class _ContactPanelState extends State<ContactPanel> {
  bool _revealed = false;

  Future<void> _call(AppStrings strings) async {
    final messenger = ScaffoldMessenger.of(context);
    if (await widget.launcher.call(widget.number)) return;
    if (!mounted) return;

    messenger.showSnackBar(SnackBar(content: Text(strings.couldNotOpenDialer)));
  }

  Future<void> _whatsApp(AppStrings strings) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await widget.launcher.whatsApp(
      widget.number,
      message: strings.whatsAppMessage,
    );
    if (opened || !mounted) return;

    messenger.showSnackBar(
      SnackBar(content: Text(strings.couldNotOpenWhatsApp)),
    );
  }

  Future<void> _copy(AppStrings strings) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: widget.number));
    if (!mounted) return;

    messenger.showSnackBar(SnackBar(content: Text(strings.numberCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final isLight = theme.brightness == Brightness.light;

    if (!_revealed) {
      return Container(
        padding: const EdgeInsets.all(BrandSizing.spaceMd),
        decoration: BoxDecoration(
          color: isLight ? BrandColours.warmSand : BrandColours.darkElevated,
          borderRadius: BrandRadius.mediumAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.contactHiddenNotice,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: BrandSizing.spaceMd),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _revealed = true),
                icon: const Icon(Icons.visibility_outlined),
                label: Text(strings.contactShow),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(BrandSizing.spaceMd),
      decoration: BoxDecoration(
        color: isLight ? BrandColours.warmSand : BrandColours.darkElevated,
        borderRadius: BrandRadius.mediumAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.phone_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: BrandSizing.spaceSm + 4),
              Expanded(
                child: SelectableText(
                  widget.number,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  // A phone number reads left to right even in an
                  // otherwise right-to-left interface.
                  textDirection: TextDirection.ltr,
                ),
              ),
              IconButton(
                onPressed: () => _copy(strings),
                icon: const Icon(Icons.copy_outlined),
                tooltip: strings.copyNumber,
              ),
            ],
          ),
          const SizedBox(height: BrandSizing.spaceMd),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _call(strings),
                  icon: const Icon(Icons.call),
                  label: Text(strings.callNumber),
                ),
              ),
              const SizedBox(width: BrandSizing.spaceSm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _whatsApp(strings),
                  icon: const Icon(Icons.chat_outlined),
                  label: Text(strings.whatsAppNumber),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
