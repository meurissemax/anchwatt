import 'package:anchwatt/commons/utils/number_format.dart';
import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:anchwatt/main/view_models/stats_view_model.dart';
import 'package:anchwatt/main/widgets/anchwatt_sprite.dart';
import 'package:anchwatt/main/widgets/stats_card.dart';
import 'package:anchwatt/main/widgets/stats_card_capture.dart';
import 'package:anchwatt/styles/borders.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:anchwatt/styles/texts.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class StatsView extends StatelessWidget {
  static const double _maxWidth = 400;
  static const EdgeInsets _insetPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 28,
  );
  static const EdgeInsets _bodyPadding = EdgeInsets.fromLTRB(20, 44, 20, 20);
  static const double _spriteSize = 56;
  static const double _sectionSpacing = 24;
  static const double _itemSpacing = 10;

  const StatsView._();

  static Future<void> show(BuildContext context) {
    final AnchwattViewModel parent = context.read<AnchwattViewModel>();

    return showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider<StatsViewModel>(
        create: (_) => StatsViewModel(parent),
        child: const StatsView._(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();
    final StatsViewModel viewModel = context.read<StatsViewModel>();

    return Dialog(
      backgroundColor: colorSurface,
      insetPadding: _insetPadding,
      shape: const RoundedRectangleBorder(
        borderRadius: borderRadiusOptionsDialog,
      ),
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(),
        },
        child: Focus(
          autofocus: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _maxWidth,
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: _bodyPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Hero(
                        evolution: viewModel.evolution,
                        isShiny: viewModel.isShiny,
                        stageLabel: viewModel.stageLabel,
                        flavor: viewModel.stageFlavor,
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsLevelLabel,
                        value: formatNumber(viewModel.level),
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsLifetimeXpLabel,
                        value: formatNumber(viewModel.lifetimeXp),
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsWakeupsLabel,
                        value: formatNumber(viewModel.totalWakeups),
                        sub: l10n.statsWakeupsDescription,
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsFavoriteEventLabel,
                        value: viewModel.favoriteEventLabel,
                        sub: l10n.statsFavoriteEventDescription,
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsSoundsPlayedLabel,
                        value: formatNumber(viewModel.soundsPlayed),
                        sub: viewModel.soundsSplit,
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsSoundDurationLabel,
                        value: viewModel.soundDuration,
                        sub: l10n.statsSoundDurationDescription,
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsShinyLabel,
                        value: formatNumber(viewModel.shinyEncounters),
                        sub: l10n.statsShinyDescription,
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsPetsLabel,
                        value: formatNumber(viewModel.petPokes),
                        sub: l10n.statsPetsDescription,
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsMemberSinceLabel,
                        value: viewModel.memberSince,
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _AchievementsSection(
                        achievements: viewModel.achievements,
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      const _ShareButton(),
                    ],
                  ),
                ),
                const Positioned(
                  top: 4,
                  right: 4,
                  child: _CloseButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  static const double _spriteToLabelSpacing = 8;

  final Evolution evolution;
  final bool isShiny;
  final String stageLabel;
  final String flavor;

  const _Hero({
    required this.evolution,
    required this.isShiny,
    required this.stageLabel,
    required this.flavor,
  });

  @override
  Widget build(BuildContext context) {
    final Widget sprite = Image.asset(
      evolution.assetPath,
      width: StatsView._spriteSize,
      height: StatsView._spriteSize,
      filterQuality: FilterQuality.none,
    );

    return Column(
      children: [
        // Same recolour as the live sprite and the share card, so an active
        // shiny window shows on the panel you share the card from.
        if (isShiny)
          ColorFiltered(
            colorFilter: AnchwattSprite.shinyColorFilter,
            child: sprite,
          )
        else
          sprite,
        const SizedBox(
          height: _spriteToLabelSpacing,
        ),
        Text(
          stageLabel,
          style: textStageLabel.copyWith(
            color: evolution.accentColor,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          flavor,
          style: textOptionsSectionDescription,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;

  const _StatRow({
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final String? sub = this.sub;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textOptionsSectionLabel,
              ),
              if (sub != null) ...[
                const SizedBox(
                  height: 4,
                ),
                Text(
                  sub,
                  style: textOptionsSectionDescription,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(
          width: StatsView._itemSpacing,
        ),
        Text(
          value,
          style: textStatValue,
        ),
      ],
    );
  }
}

class _CloseButton extends StatelessWidget {
  static const double _iconSize = 14;
  static const BoxConstraints _constraints = BoxConstraints(
    minWidth: 28,
    minHeight: 28,
  );
  static const EdgeInsets _padding = EdgeInsets.all(6);

  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return IconButton(
      icon: const Icon(
        Icons.close,
        size: _iconSize,
        color: colorMutedDark,
      ),
      tooltip: l10n.optionsCloseTooltip,
      iconSize: _iconSize,
      padding: _padding,
      constraints: _constraints,
      onPressed: () => Navigator.of(context).pop(),
    );
  }
}

class _ShareButton extends StatelessWidget {
  static const double _iconSize = 15;
  static const double _spacing = 8;
  static const Duration _animationDuration = Duration(milliseconds: 150);
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 11,
  );

  const _ShareButton();

  // Renders the card off-screen and hands it to the ViewModel. The Overlay and
  // the image precache both need this live context, so the capture closure is
  // built here (in the view) and the VM only orchestrates the copy + status.
  Future<void> _share(BuildContext context) async {
    final StatsViewModel viewModel = context.read<StatsViewModel>();
    final OverlayState overlay = Overlay.of(context);
    final StatsCardData data = viewModel.buildCardData();

    await precacheImage(AssetImage(data.evolution.assetPath), context);

    if (!context.mounted) {
      return;
    }

    await precacheImage(const AssetImage(StatsCard.logoAsset), context);

    if (!context.mounted) {
      return;
    }

    await viewModel.shareCard(
      () => captureStatsCard(
        overlay: overlay,
        card: StatsCard(
          data: data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Selector<StatsViewModel, ShareStatus>(
      selector: (_, StatsViewModel viewModel) => viewModel.shareStatus,
      builder: (context, ShareStatus status, _) {
        final bool working = status == ShareStatus.working;

        final (IconData icon, String label) = switch (status) {
          ShareStatus.idle || ShareStatus.working => (Icons.ios_share, l10n.statsCardShareButton),
          ShareStatus.copied => (Icons.check, l10n.statsCardShareCopied),
          ShareStatus.error => (Icons.error_outline, l10n.statsCardShareError),
        };

        return MouseRegion(
          cursor: working ? SystemMouseCursors.basic : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: working ? null : () => _share(context),
            child: AnimatedContainer(
              duration: _animationDuration,
              padding: _padding,
              decoration: const BoxDecoration(
                color: colorPrimary,
                borderRadius: borderRadiusOptionsButton,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: _spacing,
                children: [
                  if (working)
                    const SizedBox(
                      width: _iconSize,
                      height: _iconSize,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  else
                    Icon(
                      icon,
                      size: _iconSize,
                      color: Colors.white,
                    ),
                  Text(
                    label,
                    style: textOptionsCompactButton.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  static const double _titleSpacing = 12;
  static const double _tileSpacing = 8;

  final List<({Achievement achievement, bool unlocked})> achievements;

  const _AchievementsSection({
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.statsAchievementsTitle,
          style: textOptionsSectionLabel,
        ),
        const SizedBox(
          height: _titleSpacing,
        ),
        for (int i = 0; i < achievements.length; i++) ...[
          if (i > 0)
            const SizedBox(
              height: _tileSpacing,
            ),
          _AchievementTile(
            achievement: achievements[i].achievement,
            unlocked: achievements[i].unlocked,
          ),
        ],
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  static const EdgeInsets _padding = EdgeInsets.all(12);
  static const double _iconChipSize = 36;
  static const double _iconSize = 20;
  static const double _chipToTextSpacing = 12;
  static const double _labelToDescriptionSpacing = 3;

  final Achievement achievement;
  final bool unlocked;

  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: unlocked ? colorAchievementTileUnlocked : colorAchievementTileLocked,
        borderRadius: borderRadiusOptionsAboutCard,
      ),
      child: Row(
        children: [
          // Unlocked: a filled accent chip with a white glyph, so an earned
          // badge reads as a splash of colour. Locked: a hollow, greyed-out
          // chip, keeping the two states unmistakable at a glance.
          Container(
            width: _iconChipSize,
            height: _iconChipSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: unlocked ? achievement.accentColor : Colors.transparent,
              borderRadius: borderRadiusOptionsButton,
              border: unlocked ? null : Border.all(color: colorNeutralLight),
            ),
            child: Icon(
              achievement.iconData,
              size: _iconSize,
              color: unlocked ? Colors.white : colorMutedLight,
            ),
          ),
          const SizedBox(
            width: _chipToTextSpacing,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  achievement.label(l10n),
                  style: textOptionsSectionLabel.copyWith(
                    color: unlocked ? colorNeutralDark : colorMutedDark,
                  ),
                ),
                const SizedBox(
                  height: _labelToDescriptionSpacing,
                ),
                Text(
                  achievement.description(l10n),
                  style: textOptionsSectionDescription,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
