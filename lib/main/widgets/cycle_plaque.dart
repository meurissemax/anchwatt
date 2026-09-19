import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/styles/borders.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:anchwatt/styles/shadows.dart';
import 'package:anchwatt/styles/texts.dart';
import 'package:material_ui/material_ui.dart';

// The cycle emblem: a small dark pill ringed and lettered in the tier's
// metallic gradient, with a faint halo of the same metal. Sized to its content
// so it reads as a medal rather than a banner, and entirely static — no
// animation, no listener — so it never repaints on its own. [large] is the
// showcase size used on the stats card and in the cycle dialog.
class CyclePlaque extends StatelessWidget {
  /* Static variables */

  static const double _ringWidth = 1;
  static const double _glowOpacity = 0.35;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 4,
  );
  static const EdgeInsets _paddingLarge = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 6,
  );

  /* Variables */

  final int cycleCount;
  final bool large;

  /* Constructor */

  const CyclePlaque({
    required this.cycleCount,
    this.large = false,
    super.key,
  });

  /* Methods */

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();
    final CycleTier tier = CycleTier.fromCycleCount(cycleCount);
    final LinearGradient gradient = tier.gradient;

    // The ring is the gradient showing through a hairline of padding around
    // the dark core; both are pills, so the ring stays even all around.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadiusCyclePlaque,
        boxShadow: shadowCyclePlaque(tier.accentColor.withValues(alpha: _glowOpacity)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_ringWidth),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: colorCyclePlaqueBackground,
            borderRadius: borderRadiusCyclePlaque,
          ),
          child: Padding(
            padding: large ? _paddingLarge : _padding,
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: gradient.createShader,
              child: Text(
                l10n.cyclePlaque(AnchwattSettings.cycleNumeral(cycleCount)),
                style: large ? textCyclePlaqueLarge : textCyclePlaque,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
