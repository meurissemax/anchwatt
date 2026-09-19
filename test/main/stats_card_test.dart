import 'package:anchwatt/commons/utils/number_format.dart';
import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/widgets/stats_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

StatsCardData _data({
  List<Achievement> badges = const <Achievement>[],
  bool isShiny = false,
  int cycleCount = 0,
  int lifetimeXp = 0,
}) => StatsCardData(
  level: 12,
  xpInLevel: 30,
  xpForLevel: 100,
  evolution: Evolution.anchwatt,
  isShiny: isShiny,
  cycleCount: cycleCount,
  lifetimeXp: lifetimeXp,
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

  // The recolour is the only shiny marker the card carries — a snapshot taken
  // during a shiny window wraps the sprite in the hue-rotation filter, and a
  // normal snapshot applies no filter at all.
  testWidgets('recolours the sprite when the snapshot is shiny', (tester) async {
    await tester.pumpWidget(_host(_data(isShiny: true)));
    await tester.pump();

    expect(
      find.descendant(of: find.byType(StatsCard), matching: find.byType(ColorFiltered)),
      findsOneWidget,
    );
  });

  testWidgets('applies no filter when the snapshot is not shiny', (tester) async {
    await tester.pumpWidget(_host(_data()));
    await tester.pump();

    expect(
      find.descendant(of: find.byType(StatsCard), matching: find.byType(ColorFiltered)),
      findsNothing,
    );
  });

  // The band is the card's only trace of the cycle system: absent until the
  // first cycle, so a never-cycled card renders exactly as before.
  testWidgets('leaves the card free of any cycle band at cycle 0', (tester) async {
    await tester.pumpWidget(_host(_data(lifetimeXp: 12345)));
    await tester.pump();

    expect(find.text(locator<L10n>().statsLifetimeXpLabel), findsNothing);
    expect(find.text(formatNumber(12345)), findsNothing);
  });

  testWidgets('shows the cycle numeral and the lifetime XP from the first cycle on', (tester) async {
    final L10n l10n = locator<L10n>();

    await tester.pumpWidget(
      _host(
        _data(
          cycleCount: 4,
          lifetimeXp: 12345,
        ),
      ),
    );
    await tester.pump();

    expect(find.text(l10n.cyclePlaque('IV')), findsOneWidget);
    expect(find.text(l10n.cycleTierSteel), findsOneWidget);
    expect(find.text(formatNumber(12345)), findsOneWidget);
    expect(find.text(l10n.statsLifetimeXpLabel), findsOneWidget);
  });
}
