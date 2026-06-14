import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:anchwatt/main/view_models/stats_view_model.dart';
import 'package:anchwatt/styles/borders.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:anchwatt/styles/texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                        stageLabel: viewModel.stageLabel,
                        flavor: viewModel.stageFlavor,
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsLevelLabel,
                        value: '${viewModel.level}',
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsLifetimeXpLabel,
                        value: '${viewModel.lifetimeXp}',
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsWakeupsLabel,
                        value: '${viewModel.totalWakeups}',
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
                        value: '${viewModel.soundsPlayed}',
                        sub: viewModel.soundsSplit,
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsPetsLabel,
                        value: '${viewModel.petPokes}',
                        sub: l10n.statsPetsDescription,
                      ),
                      const SizedBox(
                        height: _sectionSpacing,
                      ),
                      _StatRow(
                        label: l10n.statsMemberSinceLabel,
                        value: viewModel.memberSince,
                      ),
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
  final String stageLabel;
  final String flavor;

  const _Hero({
    required this.evolution,
    required this.stageLabel,
    required this.flavor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          evolution.assetPath,
          width: StatsView._spriteSize,
          height: StatsView._spriteSize,
          filterQuality: FilterQuality.none,
        ),
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
