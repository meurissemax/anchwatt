import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:anchwatt/styles/borders.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SoundModePill extends StatelessWidget {
  static const double _iconSize = 14;
  static const Duration _animationDuration = Duration(milliseconds: 150);
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 6,
  );

  const SoundModePill({super.key});

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();
    final ValueNotifier<SoundMode> notifier = context.read<AnchwattViewModel>().soundModeNotifier;

    return ValueListenableBuilder<SoundMode>(
      valueListenable: notifier,
      builder: (_, mode, _) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: mode.tooltip(l10n),
          child: GestureDetector(
            onTap: () => context.read<AnchwattViewModel>().toggleSoundMode(),
            child: AnimatedContainer(
              duration: _animationDuration,
              decoration: BoxDecoration(
                color: mode.accentColor,
                borderRadius: borderRadiusOptionsButton,
              ),
              padding: _padding,
              child: Icon(
                mode.iconData,
                color: Colors.white,
                size: _iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
