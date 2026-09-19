import 'package:anchwatt/commons/utils/number_format.dart';
import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/widgets/cycle_confirmation_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// Hosts a button that opens the dialog and reports what it resolved to, so the
// yes/no contract is asserted through the real showDialog round trip.
class _Host extends StatelessWidget {
  final void Function(bool confirmed) onResult;

  const _Host({
    required this.onResult,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async => onResult(
                await CycleConfirmationDialog.show(
                  context,
                  nextCycle: 2,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _open(WidgetTester tester, void Function(bool confirmed) onResult) async {
  await tester.pumpWidget(
    _Host(
      onResult: onResult,
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    if (!locator.isRegistered<L10n>()) {
      locator.registerSingleton<L10n>(L10n());
    }
  });

  // The destructive path only ever opens on an explicit confirmation.
  testWidgets('resolves true on confirm', (tester) async {
    bool? result;
    await _open(tester, (confirmed) => result = confirmed);

    await tester.tap(find.text(locator<L10n>().cycleDialogConfirm));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('resolves false on cancel', (tester) async {
    bool? result;
    await _open(tester, (confirmed) => result = confirmed);

    await tester.tap(find.text(locator<L10n>().cycleDialogCancel));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('resolves false on Escape', (tester) async {
    bool? result;
    await _open(tester, (confirmed) => result = confirmed);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  // The reward comes first: the plaque the next cycle earns, with its tier.
  testWidgets('previews the plaque of the next cycle', (tester) async {
    final L10n l10n = locator<L10n>();
    await _open(tester, (_) {});

    expect(find.text(l10n.cycleDialogTitle('II')), findsOneWidget);
    expect(find.text(l10n.cyclePlaque('II')), findsOneWidget);
    expect(find.text(l10n.cycleTierCopper), findsOneWidget);
  });

  // The three losses are the whole point of the dialog: they must all be there.
  testWidgets('spells out the three losses', (tester) async {
    final L10n l10n = locator<L10n>();
    await _open(tester, (_) {});

    expect(find.text(l10n.cycleDialogLossLevel), findsOneWidget);
    expect(find.text(l10n.cycleDialogLossForm), findsOneWidget);
    expect(
      find.text(l10n.cycleDialogLossHardcore(formatNumber(AnchwattSettings.hardcoreUnlockLevel))),
      findsOneWidget,
    );
  });
}
