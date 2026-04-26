import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/view_models/home_view_model.dart';
import 'package:anchwatt/main/widgets/anchwatt_sprite.dart';
import 'package:anchwatt/main/widgets/xp_progress_bar.dart';
import 'package:anchwatt/settings.dart';
import 'package:anchwatt/styles/borders.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:anchwatt/styles/texts.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

@RoutePage()
class HomeView extends StatelessWidget {
  static const String path = '/home';

  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (_) => HomeViewModel(),
      child: const _HomeViewBody(),
    );
  }
}

class _HomeViewBody extends StatelessWidget {
  const _HomeViewBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 20),
          child: Column(
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
              const _XpProgressBarSelector(),
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

    return Selector<HomeViewModel, ({int level, Evolution evolution})>(
      selector: (_, vm) => (
        level: vm.level,
        evolution: vm.evolution,
      ),
      builder: (_, data, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${data.level}',
            style: textLevel,
          ),
          const SizedBox(
            width: 10,
          ),
          Padding(
            padding: const EdgeInsets.only(
              bottom: 8,
            ),
            child: Text(
              l10n.homeEvolutionLevel(data.level, data.evolution.label(l10n)),
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
    return Selector<HomeViewModel, Evolution>(
      selector: (_, vm) => vm.evolution,
      builder: (_, evolution, _) => AnchwattSprite(
        evolution: evolution,
      ),
    );
  }
}

class _XpProgressBarSelector extends StatelessWidget {
  const _XpProgressBarSelector();

  @override
  Widget build(BuildContext context) {
    return Selector<HomeViewModel, ({double progress, Evolution evolution})>(
      selector: (_, vm) => (progress: vm.progress, evolution: vm.evolution),
      builder: (_, data, _) => XpProgressBar(
        progress: data.progress,
        color: data.evolution.accentColor,
      ),
    );
  }
}

class _XpCounterText extends StatelessWidget {
  const _XpCounterText();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Selector<HomeViewModel, ({int xp, int xpToNextLevel})>(
      selector: (_, vm) => (xp: vm.xp, xpToNextLevel: vm.xpToNextLevel),
      builder: (_, data, _) => Text(
        l10n.homeXpCounter(data.xp, data.xpToNextLevel),
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
      onPressed: () => context.read<HomeViewModel>().addXp(),
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
      child: Text(l10n.homeDebugAddXp),
    );
  }
}
