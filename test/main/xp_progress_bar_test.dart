import 'package:anchwatt/main/widgets/xp_progress_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The bar is laid out in a fixed 100px-wide box, so the filled ColoredBox width
// reads directly as the displayed progress fraction (0..1).
const double _barWidth = 100;

Widget _host({required int level, required double progress}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: SizedBox(
      width: _barWidth,
      child: XpProgressBar(
        level: level,
        progress: progress,
        color: const Color(0xFF00FF00),
      ),
    ),
  ),
);

double _fillFraction(WidgetTester tester) => tester.getSize(find.byType(ColoredBox)).width / _barWidth;

void main() {
  // Regression: on boot the ViewModel briefly holds the placeholder (level 1,
  // xp 0) before loading the persisted state, so the bar sees a jump like
  // 1 -> 20. That must snap, not replay a roll-over for each of the 19 paliers.
  testWidgets('snaps on a multi-level jump (boot hydration) instead of rolling over', (tester) async {
    await tester.pumpWidget(_host(level: 1, progress: 0));
    await tester.pumpWidget(_host(level: 20, progress: 0.5));
    await tester.pump();

    expect(_fillFraction(tester), moreOrLessEquals(0.5, epsilon: 0.001));
  });

  testWidgets('rolls over on a single level-up', (tester) async {
    await tester.pumpWidget(_host(level: 5, progress: 0.9));
    await tester.pumpWidget(_host(level: 6, progress: 0.1));
    await tester.pump();

    // Mid-animation it fills the old palier toward full, rather than sitting at
    // the new low fill straight away.
    await tester.pump(const Duration(milliseconds: 100));
    expect(_fillFraction(tester), greaterThan(0.5));

    // It settles at the new palier's fraction once the roll-over completes.
    await tester.pumpAndSettle();
    expect(_fillFraction(tester), moreOrLessEquals(0.1, epsilon: 0.02));
  });
}
