import 'dart:async';

import 'package:anchwatt/commons/utils/number_format.dart';
import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/update_service.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:anchwatt/main/views/options_view.dart';
import 'package:anchwatt/main/views/stats_view.dart';
import 'package:anchwatt/main/widgets/anchwatt_sprite.dart';
import 'package:anchwatt/main/widgets/pet_gesture_surface.dart';
import 'package:anchwatt/main/widgets/sound_mode_pill.dart';
import 'package:anchwatt/main/widgets/system_volume_pill.dart';
import 'package:anchwatt/main/widgets/xp_gain_floater.dart';
import 'package:anchwatt/main/widgets/xp_progress_bar.dart';
import 'package:anchwatt/settings.dart';
import 'package:anchwatt/styles/borders.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:anchwatt/styles/gradients.dart';
import 'package:anchwatt/styles/texts.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class AnchwattView extends StatelessWidget {
  static const String path = '/anchwatt';

  const AnchwattView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AnchwattViewModel>(
      create: (_) => AnchwattViewModel(),
      child: const _AnchwattViewBody(),
    );
  }
}

class _AnchwattViewBody extends StatelessWidget {
  const _AnchwattViewBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 10,
                children: [
                  SystemVolumePill(),
                  SoundModePill(),
                  _SilentModeButton(),
                  _StatsButton(),
                  _OptionsButton(),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              const _LevelHeader(),
              const SizedBox(
                height: 16,
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Align(
                    alignment: Alignment(0.1, 0),
                    child: _SpriteSelector(),
                  ),
                ),
              ),
              const _XpSection(),
              if (Settings.isDev) ...[
                const SizedBox(
                  height: 20,
                ),
                const Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: _DebugAddXpButton(),
                    ),
                    Expanded(
                      child: _DebugSimulateEventButton(),
                    ),
                    Expanded(
                      child: _DebugToggleShinyButton(),
                    ),
                    Expanded(
                      child: _DebugResetStatsButton(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelHeader extends StatelessWidget {
  const _LevelHeader();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Selector<AnchwattViewModel, ({int level, Evolution evolution, bool isMaxLevel})>(
      selector: (_, vm) => (
        level: vm.level,
        evolution: vm.evolution,
        isMaxLevel: vm.isMaxLevel,
      ),
      builder: (_, data, _) {
        final Text level = Text(
          formatNumber(data.level),
          style: textLevel,
        );

        return Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          spacing: 14,
          children: [
            if (data.isMaxLevel)
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => gradientLevelMax.createShader(bounds),
                child: level,
              )
            else
              level,
            Text(
              data.evolution.label(l10n),
              style: textStageLabel,
            ),
          ],
        );
      },
    );
  }
}

class _SpriteSelector extends StatelessWidget {
  const _SpriteSelector();

  @override
  Widget build(BuildContext context) {
    return PetGestureSurface(
      child: ValueListenableBuilder<bool>(
        valueListenable: context.read<AnchwattViewModel>().silentModeNotifier,
        builder: (_, silentMode, _) => Selector<AnchwattViewModel, ({Evolution evolution, bool isShiny})>(
          selector: (_, vm) => (evolution: vm.evolution, isShiny: vm.isShiny),
          builder: (_, data, _) => AnchwattSprite(
            evolution: data.evolution,
            muted: silentMode,
            isShiny: data.isShiny,
          ),
        ),
      ),
    );
  }
}

class _XpSection extends StatelessWidget {
  const _XpSection();

  @override
  Widget build(BuildContext context) {
    return Selector<AnchwattViewModel, bool>(
      selector: (_, vm) => vm.isMaxLevel,
      builder: (_, isMaxLevel, _) {
        if (isMaxLevel) {
          return const SizedBox.shrink();
        }

        return const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 20,
            ),
            _XpGauge(),
            SizedBox(
              height: 10,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: _XpCounterText(),
            ),
          ],
        );
      },
    );
  }
}

class _XpGauge extends StatefulWidget {
  const _XpGauge();

  @override
  State<_XpGauge> createState() => _XpGaugeState();
}

class _XpGaugeState extends State<_XpGauge> {
  /* Variables */

  final List<_FloaterEntry> _floaters = [];
  StreamSubscription<int>? _subscription;

  /* Methods */

  @override
  void initState() {
    super.initState();

    _subscription = context.read<AnchwattViewModel>().xpGainStream.listen(_onGain);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onGain(int amount) {
    final Color color = context.read<AnchwattViewModel>().evolution.accentColor;

    setState(() {
      _floaters.add(
        _FloaterEntry(
          key: UniqueKey(),
          amount: amount,
          color: color,
        ),
      );
    });
  }

  void _onCompleted(Key key) {
    setState(() {
      _floaters.removeWhere((entry) => entry.key == key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Selector<AnchwattViewModel, ({int level, double progress, Evolution evolution})>(
          selector: (_, vm) => (level: vm.level, progress: vm.progress, evolution: vm.evolution),
          builder: (_, data, _) => XpProgressBar(
            level: data.level,
            progress: data.progress,
            color: data.evolution.accentColor,
          ),
        ),
        for (final _FloaterEntry entry in _floaters)
          Positioned(
            top: 0,
            right: 0,
            child: XpGainFloater(
              key: entry.key,
              amount: entry.amount,
              color: entry.color,
              onCompleted: () => _onCompleted(entry.key),
            ),
          ),
      ],
    );
  }
}

class _FloaterEntry {
  final Key key;
  final int amount;
  final Color color;

  const _FloaterEntry({
    required this.key,
    required this.amount,
    required this.color,
  });
}

class _XpCounterText extends StatelessWidget {
  const _XpCounterText();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Selector<AnchwattViewModel, ({int xp, int xpToNextLevel})>(
      selector: (_, vm) => (xp: vm.xp, xpToNextLevel: vm.xpToNextLevel),
      builder: (_, data, _) => Text(
        l10n.anchwattXpCounter(formatNumber(data.xp), formatNumber(data.xpToNextLevel)),
        style: textXpCounter,
      ),
    );
  }
}

class _DebugAddXpButton extends StatelessWidget {
  const _DebugAddXpButton();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return OutlinedButton(
      onPressed: () => context.read<AnchwattViewModel>().debugAddXp(),
      style: OutlinedButton.styleFrom(
        enabledMouseCursor: SystemMouseCursors.click,
        foregroundColor: colorNeutralDark,
        side: const BorderSide(
          color: colorNeutralLight,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: borderRadiusDebugButton,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        textStyle: textDebugButton,
      ),
      child: Text(l10n.anchwattDebugAddXp),
    );
  }
}

class _DebugSimulateEventButton extends StatelessWidget {
  const _DebugSimulateEventButton();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return OutlinedButton(
      onPressed: () => context.read<AnchwattViewModel>().debugSimulateEvent(),
      style: OutlinedButton.styleFrom(
        enabledMouseCursor: SystemMouseCursors.click,
        foregroundColor: colorNeutralDark,
        side: const BorderSide(
          color: colorNeutralLight,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: borderRadiusDebugButton,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        textStyle: textDebugButton,
      ),
      child: Text(l10n.anchwattDebugSimulateEvent),
    );
  }
}

class _DebugToggleShinyButton extends StatelessWidget {
  const _DebugToggleShinyButton();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return OutlinedButton(
      onPressed: () => context.read<AnchwattViewModel>().debugToggleShiny(),
      style: OutlinedButton.styleFrom(
        enabledMouseCursor: SystemMouseCursors.click,
        foregroundColor: colorNeutralDark,
        side: const BorderSide(
          color: colorNeutralLight,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: borderRadiusDebugButton,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        textStyle: textDebugButton,
      ),
      child: Text(l10n.anchwattDebugToggleShiny),
    );
  }
}

class _DebugResetStatsButton extends StatelessWidget {
  const _DebugResetStatsButton();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return OutlinedButton(
      onPressed: () => context.read<AnchwattViewModel>().debugResetStats(),
      style: OutlinedButton.styleFrom(
        enabledMouseCursor: SystemMouseCursors.click,
        foregroundColor: colorError,
        side: const BorderSide(
          color: colorError,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: borderRadiusDebugButton,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        textStyle: textDebugButton,
      ),
      child: Text(l10n.anchwattDebugResetStats),
    );
  }
}

class _SilentModeButton extends StatelessWidget {
  static const double _iconSize = 14;
  static const Duration _animationDuration = Duration(milliseconds: 150);
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 6,
  );

  const _SilentModeButton();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();
    final ValueNotifier<bool> notifier = context.read<AnchwattViewModel>().silentModeNotifier;

    return ValueListenableBuilder<bool>(
      valueListenable: notifier,
      builder: (_, enabled, _) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: enabled ? l10n.silentModeTooltipEnabled : l10n.silentModeTooltipDisabled,
          child: GestureDetector(
            onTap: () => context.read<AnchwattViewModel>().toggleSilentMode(),
            child: AnimatedContainer(
              duration: _animationDuration,
              decoration: BoxDecoration(
                color: enabled ? colorWarning : colorNeutralLight,
                borderRadius: borderRadiusOptionsButton,
              ),
              padding: _padding,
              child: Icon(
                Icons.bedtime,
                size: _iconSize,
                color: enabled ? Colors.white : colorMutedDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsButton extends StatelessWidget {
  static const double _iconSize = 14;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 6,
  );

  const _StatsButton();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: l10n.statsButtonTooltip,
        child: GestureDetector(
          onTap: () => StatsView.show(context),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: colorNeutralLight,
              borderRadius: borderRadiusOptionsButton,
            ),
            child: Padding(
              padding: _padding,
              child: Icon(
                Icons.emoji_events,
                size: _iconSize,
                color: colorMutedDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionsButton extends StatelessWidget {
  static const double _iconSize = 14;
  static const double _dotSize = 7;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 6,
  );

  const _OptionsButton();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Selector<AnchwattViewModel, bool>(
      selector: (_, vm) => vm.updateStatus is UpdateAvailable,
      builder: (_, hasUpdate, _) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: l10n.optionsButtonTooltip,
          child: GestureDetector(
            onTap: () => OptionsView.show(context),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: colorNeutralLight,
                borderRadius: borderRadiusOptionsButton,
              ),
              child: Padding(
                padding: _padding,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.tune,
                      size: _iconSize,
                      color: colorMutedDark,
                    ),
                    if (hasUpdate)
                      const Positioned(
                        top: -3,
                        right: -3,
                        child: _UpdateDot(
                          size: _dotSize,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UpdateDot extends StatelessWidget {
  final double size;

  const _UpdateDot({
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: colorUpdateBadge,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(
            color: colorScaffoldBackground,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
