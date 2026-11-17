import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_hire/app/app.dart';
import 'package:trust_hire/app/settings_controller.dart';
import 'package:trust_hire/features/account/account_switcher.dart';
import 'package:trust_hire/services/local_store.dart';
import 'package:trust_hire/widgets/focus_ring.dart';

/// WP11: everything can be reached with the keyboard, and seen when it is.
///
/// **Material's controls drew focus; the app's own did not.** A row, the
/// view switch, the bar's posting slot and the account button marked focus
/// with an ink wash a few percent darker than nothing, so somebody tabbing
/// through lost their place at the first one. This walks the shell by Tab and
/// fails on any stop that has no visible ring, so a new custom control that
/// forgets its FocusRing fails here rather than in somebody's hands.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    rootBundle.clear();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpShell(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await LocalStore.open();
    await (SettingsController(store)..load()).markIntroSeen();
    await tester.pumpWidget(TrustHireApp(store: store));
    await settle(tester);
  }

  Future<BuildContext> tab(WidgetTester tester, {bool back = false}) async {
    if (back) await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    if (back) await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump(const Duration(milliseconds: 50));
    return FocusManager.instance.primaryFocus!.context!;
  }

  T? ancestor<T extends Widget>(BuildContext context) =>
      context.findAncestorWidgetOfExactType<T>() ??
      (context.widget is T ? context.widget as T : null);

  /// Why the focused control at [context] can be seen, or null if it cannot.
  String? howItShows(BuildContext context) {
    final ring = context.findAncestorStateOfType<FocusRingState>();
    if (ring != null) return ring.isShowing ? 'FocusRing' : null;

    // Material's own controls, through the theme's focused outline.
    final theme = Theme.of(context);
    BorderSide? focused(ButtonStyle? style) =>
        style?.side?.resolve({WidgetState.focused});
    final side = switch (null) {
      _ when ancestor<TextButton>(context) != null => focused(
        theme.textButtonTheme.style,
      ),
      _ when ancestor<IconButton>(context) != null => focused(
        theme.iconButtonTheme.style,
      ),
      _ when ancestor<FilledButton>(context) != null => focused(
        theme.filledButtonTheme.style,
      ),
      _ when ancestor<OutlinedButton>(context) != null => focused(
        theme.outlinedButtonTheme.style,
      ),
      _ when ancestor<ElevatedButton>(context) != null => focused(
        theme.elevatedButtonTheme.style,
      ),
      _ when ancestor<EditableText>(context) != null =>
        theme.inputDecorationTheme.focusedBorder?.borderSide,
      _ => null,
    };
    if (side != null && side.width >= 2) return 'theme outline';

    // Toggles draw their own focus halo.
    if (ancestor<Checkbox>(context) != null ||
        ancestor<Radio<Object?>>(context) != null ||
        ancestor<Switch>(context) != null) {
      return 'toggle halo';
    }
    return null;
  }

  String describe(BuildContext context) {
    final chain = <String>[];
    context.visitAncestorElements((element) {
      final name = element.widget.runtimeType.toString();
      if (!name.startsWith('_') && chain.length < 12) chain.add(name);
      return true;
    });
    return chain.join(' < ');
  }

  for (final (name, size) in const [
    ('a phone', Size(390, 844)),
    ('a desktop browser', Size(1440, 900)),
  ]) {
    testWidgets('every stop on the way round shows a ring ($name)', (
      tester,
    ) async {
      await pumpShell(tester, size);

      final seen = <Element>{};
      var reachedTheMap = false;
      for (var i = 0; i < 40; i++) {
        final context = await tab(tester);
        final element = context as Element;
        // A fixed walk rather than "once round": focusing a row scrolls the
        // list, and the order is by position, so a stop can come round
        // again before the last one has been reached.
        seen.add(element);
        // The map takes focus for its own arrow-key panning, so it is a
        // stop like any other and must show it.
        if (ancestor<FlutterMap>(context) != null) reachedTheMap = true;
        expect(
          howItShows(context),
          isNotNull,
          reason: 'stop $i has no visible focus: ${describe(context)}',
        );
      }
      expect(seen.length, greaterThan(10), reason: 'the walk went nowhere');
      expect(reachedTheMap, isTrue);
    });
  }

  testWidgets('arrow keys move along the bar', (tester) async {
    await pumpShell(tester, const Size(390, 844));

    // Tab into the bar.
    BuildContext context;
    var i = 0;
    do {
      context = await tab(tester);
    } while (ancestor<NavigationBar>(context) == null && ++i < 40);
    expect(ancestor<NavigationBar>(context), isNotNull);

    final before = FocusManager.instance.primaryFocus;
    final x = tester.getCenter(find.byElementPredicate((e) => e == context)).dx;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 50));

    final after = FocusManager.instance.primaryFocus!;
    expect(after, isNot(before));
    expect(ancestor<NavigationBar>(after.context!), isNotNull);
    expect(
      tester.getCenter(find.byElementPredicate((e) => e == after.context)).dx,
      greaterThan(x),
    );
  });

  testWidgets('Escape closes a sheet, and focus goes back where it was', (
    tester,
  ) async {
    await pumpShell(tester, const Size(390, 844));

    // The account button, by keyboard.
    BuildContext context;
    var i = 0;
    do {
      context = await tab(tester);
    } while (context.findAncestorWidgetOfExactType<Tooltip>()?.message !=
            'Switch account' &&
        ++i < 40);
    final opener = FocusManager.instance.primaryFocus;

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle(tester);
    expect(find.byType(AccountSheet), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(find.byType(AccountSheet), findsNothing);
    expect(FocusManager.instance.primaryFocus, opener);
  });
}
