import 'package:flutter/material.dart';

import '../../core/tokens.dart';
import '../../widgets/state_views.dart';

/// Posting a job. Built out in Sprint 3.
///
/// Sprint 0 wires the route so the primary action in the shell is reachable
/// and the navigation scaffold is genuinely complete.
class CreateJobScreen extends StatelessWidget {
  const CreateJobScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post a job'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(BrandSizing.spaceLg),
        child: EmptyView(
          icon: Icons.mic_none,
          title: 'What work do you need?',
          message:
              'Posting arrives in Sprint 3 — a voice note, a photo or a short '
              'message will each be enough on their own.',
        ),
      ),
    );
  }
}
