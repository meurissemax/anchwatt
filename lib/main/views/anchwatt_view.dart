import 'dart:async';

import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/services/update_service.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:anchwatt/main/widgets/anchwatt_sprite.dart';
import 'package:anchwatt/main/widgets/pet_gesture_surface.dart';
import 'package:anchwatt/main/widgets/sound_mode_pill.dart';
import 'package:anchwatt/main/widgets/system_volume_pill.dart';
import 'package:anchwatt/main/widgets/xp_gain_floater.dart';
import 'package:anchwatt/main/widgets/xp_progress_bar.dart';
import 'package:anchwatt/settings.dart';
import 'package:anchwatt/styles/borders.dart';
import 'package:anchwatt/styles/colors.dart';
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
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LevelHeader(),
                  const SizedBox(
                    height: 8,
                  ),
                  const Expanded(
                    child: Align(
                      alignment: Alignment(0.1, 0),
                      child: _SpriteSelector(),
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  const _XpGauge(),
                  const SizedBox(
                    height: 6,
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: _XpCounterText(),
                  ),
                  if (Settings.isDev) ...[
                    const SizedBox(
                      height: 16,
                    ),
                    const _DebugAddXpButton(),
                  ],
                ],
              ),
              const Positioned(
                top: 0,
                right: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    _UpdateBadge(),
                    SystemVolumePill(),
                    SoundModePill(),
                  ],
                ),
              ),
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

    return Selector<AnchwattViewModel, ({int level, Evolution evolution})>(
      selector: (_, vm) => (
        level: vm.level,
        evolution: vm.evolution,
      ),
      builder: (_, data, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 10,
        children: [
          Text(
            '${data.level}',
            style: textLevel,
          ),
          Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
            ),
            child: Text(
              l10n.anchwattEvolutionLevel(data.level, data.evolution.label(l10n)),
              style: textStageLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpriteSelector extends StatelessWidget {
  const _SpriteSelector();

  @override
  Widget build(BuildContext context) {
    return PetGestureSurface(
      child: Selector<AnchwattViewModel, Evolution>(
        selector: (_, vm) => vm.evolution,
        builder: (_, evolution, _) => AnchwattSprite(
          evolution: evolution,
        ),
      ),
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
        Selector<AnchwattViewModel, ({double progress, Evolution evolution})>(
          selector: (_, vm) => (progress: vm.progress, evolution: vm.evolution),
          builder: (_, data, _) => XpProgressBar(
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
        l10n.anchwattXpCounter(data.xp, data.xpToNextLevel),
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

class _UpdateBadge extends StatelessWidget {
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );

  const _UpdateBadge();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Selector<AnchwattViewModel, UpdateStatus>(
      selector: (_, vm) => vm.updateStatus,
      builder: (_, status, _) {
        if (status is! UpdateAvailable) {
          return const SizedBox.shrink();
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: l10n.anchwattUpdateBadgeTooltip,
            child: GestureDetector(
              onTap: () => context.read<AnchwattViewModel>().openLatestRelease(),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: colorUpdateBadge,
                  borderRadius: borderRadiusUpdateBadge,
                ),
                child: Padding(
                  padding: _padding,
                  child: Text(
                    l10n.anchwattUpdateBadgeLabel(status.latestVersion),
                    style: textUpdateBadge,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
