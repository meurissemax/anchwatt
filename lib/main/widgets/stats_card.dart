import 'package:anchwatt/commons/utils/number_format.dart';
import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/widgets/xp_progress_bar.dart';
import 'package:anchwatt/settings.dart';
import 'package:anchwatt/styles/borders.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:anchwatt/styles/texts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// The pure, deterministic render target for the shareable stats card. It is
// driven entirely by an immutable [StatsCardData] snapshot (never a live
// service), so the captured frame is stable, and it always draws the current
// form's NORMAL sprite — the shiny recolour is intentionally excluded. Fixed at
// 600 logical px wide by its capture host; the height is intrinsic.
class StatsCard extends StatelessWidget {
  /* Static variables */

  static const String logoAsset = 'assets/images/icons/app/icon__app.png';

  static const double _padding = 28;
  static const double _sectionSpacing = 24;

  /* Variables */

  final StatsCardData data;

  /* Constructor */

  const StatsCard({
    required this.data,
    super.key,
  });

  /* Methods */

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorSurface,
        border: Border.all(color: colorNeutralLight),
        borderRadius: borderRadiusStatsCard,
      ),
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(evolution: data.evolution),
            const SizedBox(
              height: _sectionSpacing,
            ),
            _Hero(data: data),
            const SizedBox(
              height: _sectionSpacing,
            ),
            _StatTiles(data: data),
            if (data.unlockedBadges.isNotEmpty) ...[
              const SizedBox(
                height: _sectionSpacing,
              ),
              _Badges(
                badges: data.unlockedBadges,
                accent: data.evolution.accentColor,
              ),
            ],
            const SizedBox(
              height: _sectionSpacing,
            ),
            const _CtaBar(),
            const SizedBox(
              height: 20,
            ),
            _Footer(tagline: data.tagline),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  static const double _logoSize = 34;
  static const double _logoToWordmark = 10;
  static const EdgeInsets _pillPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 6,
  );

  final Evolution evolution;

  const _Header({
    required this.evolution,
  });

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              StatsCard.logoAsset,
              width: _logoSize,
              height: _logoSize,
            ),
            const SizedBox(
              width: _logoToWordmark,
            ),
            Text(
              l10n.anchwatt,
              style: textStatsCardWordmark,
            ),
          ],
        ),
        Container(
          padding: _pillPadding,
          decoration: BoxDecoration(
            color: evolution.accentColor,
            borderRadius: borderRadiusOptionsModePill,
          ),
          child: Text(
            evolution.label(l10n),
            style: textStatsCardPill,
          ),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  static const double _spriteBoxSize = 128;
  static const double _spritePadding = 16;
  static const double _spriteToStats = 24;

  final StatsCardData data;

  const _Hero({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();
    final double progress = data.xpForLevel <= 0 ? 0 : (data.xpInLevel / data.xpForLevel).clamp(0, 1);

    return Row(
      children: [
        Container(
          width: _spriteBoxSize,
          height: _spriteBoxSize,
          padding: const EdgeInsets.all(_spritePadding),
          decoration: const BoxDecoration(
            color: colorAchievementTileUnlocked,
            borderRadius: borderRadiusOptionsAboutCard,
          ),
          child: Image.asset(
            data.evolution.assetPath,
            filterQuality: FilterQuality.none,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(
          width: _spriteToStats,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.statsLevelLabel,
                style: textStatsCardLevelLabel,
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                formatNumber(data.level),
                style: textStatsCardLevel,
              ),
              const SizedBox(
                height: 12,
              ),
              XpProgressBar(
                level: data.level,
                progress: progress,
                color: data.evolution.accentColor,
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                l10n.anchwattXpCounter(
                  formatNumber(data.xpInLevel),
                  formatNumber(data.xpForLevel),
                ),
                style: textStatsCardXpCounter,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTiles extends StatelessWidget {
  static const double _spacing = 12;

  final StatsCardData data;

  const _StatTiles({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();
    final String memberSince = DateFormat.yMMMM().format(data.memberSince);

    // IntrinsicHeight bounds the cross axis so the tiles can stretch to a shared
    // height (the card lays out with an unbounded height during capture).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatTile(
              label: l10n.statsWakeupsLabel,
              value: formatNumber(data.totalSystemEvents),
            ),
          ),
          const SizedBox(
            width: _spacing,
          ),
          Expanded(
            child: _StatTile(
              label: l10n.statsPetsLabel,
              value: formatNumber(data.petInteractions),
            ),
          ),
          const SizedBox(
            width: _spacing,
          ),
          Expanded(
            child: _StatTile(
              label: l10n.statsShinyLabel,
              value: formatNumber(data.shinyEncounters),
            ),
          ),
          const SizedBox(
            width: _spacing,
          ),
          Expanded(
            child: _StatTile(
              label: l10n.statsMemberSinceLabel,
              value: memberSince,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 14,
  );

  final String label;
  final String value;

  const _StatTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: const BoxDecoration(
        color: colorAchievementTileUnlocked,
        borderRadius: borderRadiusOptionsAboutCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Values range from short counts to a "month year" string; scaling
          // down keeps every tile on a single line at a shared baseline size.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: textStatsCardTileValue,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            label,
            style: textStatsCardTileLabel,
          ),
        ],
      ),
    );
  }
}

class _Badges extends StatelessWidget {
  static const double _titleSpacing = 12;
  static const double _chipSpacing = 8;

  final List<Achievement> badges;
  final Color accent;

  const _Badges({
    required this.badges,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.statsAchievementsTitle,
          style: textStatsCardSectionLabel,
        ),
        const SizedBox(
          height: _titleSpacing,
        ),
        Wrap(
          spacing: _chipSpacing,
          runSpacing: _chipSpacing,
          children: [
            for (final Achievement badge in badges)
              _BadgeChip(
                badge: badge,
                // Single toggle point for the badge-icon colour: swap `accent`
                // for `colorPrimary` here if the form accent ever reads too dull
                // on the light chips.
                iconColor: accent,
              ),
          ],
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  static const double _iconSize = 18;
  static const double _iconToLabel = 8;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  final Achievement badge;
  final Color iconColor;

  const _BadgeChip({
    required this.badge,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Container(
      padding: _padding,
      decoration: const BoxDecoration(
        color: colorAchievementTileUnlocked,
        borderRadius: borderRadiusOptionsButton,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badge.iconData,
            size: _iconSize,
            color: iconColor,
          ),
          const SizedBox(
            width: _iconToLabel,
          ),
          Text(
            badge.label(l10n),
            style: textStatsCardBadge,
          ),
        ],
      ),
    );
  }
}

class _CtaBar extends StatelessWidget {
  static const double _iconSize = 18;
  static const double _iconToLabel = 10;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 18,
    vertical: 14,
  );

  const _CtaBar();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();
    final String url = Settings.githubRepoUrl.replaceFirst(RegExp('^https?://'), '');

    return Container(
      padding: _padding,
      decoration: const BoxDecoration(
        color: colorPrimary,
        borderRadius: borderRadiusOptionsUpdateZone,
      ),
      // Scales down rather than overflowing if the repo URL is ever long.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.download,
              size: _iconSize,
              color: Colors.white,
            ),
            const SizedBox(
              width: _iconToLabel,
            ),
            Text(
              '${l10n.statsCardCtaLabel} — $url',
              style: textStatsCardCta,
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  static const double _hairlineToTagline = 14;

  final String tagline;

  const _Footer({
    required this.tagline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(
          color: colorNeutralLight,
          height: 1,
          thickness: 1,
        ),
        const SizedBox(
          height: _hairlineToTagline,
        ),
        Text(
          tagline,
          textAlign: TextAlign.center,
          style: textStatsCardTagline,
        ),
      ],
    );
  }
}
