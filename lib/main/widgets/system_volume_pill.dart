import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/view_models/home_view_model.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:anchwatt/styles/texts.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SystemVolumePill extends StatelessWidget {
  static const double _iconSize = 14;
  static const double _gap = 4;

  const SystemVolumePill({super.key});

  static IconData _iconFor(SystemVolumeState state) {
    if (state.muted) {
      return Icons.volume_off_rounded;
    }

    if (state.volume < SystemVolumeSettings.lowThreshold) {
      return Icons.volume_mute_rounded;
    }

    if (state.volume < SystemVolumeSettings.mediumThreshold) {
      return Icons.volume_down_rounded;
    }

    return Icons.volume_up_rounded;
  }

  static Color _colorFor(SystemVolumeState state) {
    if (state.muted) {
      return colorSystemVolumeMuted;
    }

    if (state.isLow) {
      return colorSystemVolumeLow;
    }

    return colorSystemVolumeForeground;
  }

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Selector<HomeViewModel, SystemVolumeState>(
      selector: (_, vm) => vm.systemVolumeState,
      builder: (_, state, _) {
        final Color color = _colorFor(state);

        return Tooltip(
          message: state.muted ? l10n.systemVolumeTooltipMuted : l10n.systemVolumeTooltip(state.percent),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconFor(state),
                color: color,
                size: _iconSize,
              ),
              const SizedBox(
                width: _gap,
              ),
              Text(
                '${state.percent} %',
                style: textSystemVolumeLabel.copyWith(
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
