import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/widgets/stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

StatsCardData _data({List<Achievement> badges = const <Achievement>[]}) => StatsCardData(
  level: 12,
  xpInLevel: 30,
  xpForLevel: 100,
  evolution: Evolution.anchwatt,
  totalSystemEvents: 1234,
  petInteractions: 56,
  shinyEncounters: 2,
  memberSince: DateTime(2026, 7),
  unlockedBadges: badges,
  tagline: 'Niveau 12. Tout ça pour ça.',
);

Widget _host(StatsCardData data) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 600,
        child: StatsCard(
          data: data,
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(() {
    if (!locator.isRegistered<L10n>()) {
      locator.registerSingleton<L10n>(L10n());
    }
  });

  testWidgets('builds from a snapshot and shows the level and unlocked badges', (tester) async {
    await tester.pumpWidget(
      _host(
        _data(
          badges: <Achievement>[Achievement.firstSpark, Achievement.chromatic],
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(StatsCard), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('Niveau 12. Tout ça pour ça.'), findsOneWidget);
    // One chip per unlocked badge, keyed by its distinct icon.
    expect(find.byIcon(Achievement.firstSpark.iconData), findsOneWidget);
    expect(find.byIcon(Achievement.chromatic.iconData), findsOneWidget);
  });

  testWidgets('hides the badges section when nothing is unlocked', (tester) async {
    await tester.pumpWidget(_host(_data()));
    await tester.pump();

    expect(find.byType(StatsCard), findsOneWidget);
    expect(find.text(locator<L10n>().statsAchievementsTitle), findsNothing);
  });
}
