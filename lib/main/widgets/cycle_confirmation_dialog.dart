import 'package:anchwatt/commons/utils/number_format.dart';
import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/widgets/cycle_plaque.dart';
import 'package:anchwatt/styles/borders.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:anchwatt/styles/texts.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

// Confirmation gate of the cycle reset. A plain widget rather than a view: it
// holds no state of its own and only answers a yes/no question, leaving the
// reset itself to the caller. Leads with the plaque the next cycle earns, then
// spells out what starts over — an invitation with its fine print, not a
// warning.
class CycleConfirmationDialog extends StatelessWidget {
  /* Static variables */

  static const double _maxWidth = 400;
  static const EdgeInsets _insetPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 28,
  );
  static const EdgeInsets _bodyPadding = EdgeInsets.all(20);
  static const double _titleSpacing = 16;
  static const double _plaqueToCaption = 8;
  static const double _sectionSpacing = 16;
  static const double _itemSpacing = 6;
  static const double _actionSpacing = 8;

  /* Variables */

  final int nextCycle;

  /* Constructor */

  const CycleConfirmationDialog._({
    required this.nextCycle,
  });

  /* Methods */

  // Resolves to true only on an explicit confirmation; dismissing, Escape and
  // a tap outside the dialog all resolve to false. [nextCycle] is the cycle
  // the reset would open, previewed as the plaque it earns.
  static Future<bool> show(
    BuildContext context, {
    required int nextCycle,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => CycleConfirmationDialog._(
        nextCycle: nextCycle,
      ),
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();
    final CycleTier tier = CycleTier.fromCycleCount(nextCycle);

    return Dialog(
      backgroundColor: colorSurface,
      insetPadding: _insetPadding,
      shape: const RoundedRectangleBorder(
        borderRadius: borderRadiusOptionsDialog,
      ),
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.of(context).pop(false),
        },
        child: Focus(
          autofocus: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _maxWidth,
            ),
            child: Padding(
              padding: _bodyPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.cycleDialogTitle(AnchwattSettings.cycleNumeral(nextCycle)),
                    style: textOptionsAppName,
                  ),
                  const SizedBox(
                    height: _titleSpacing,
                  ),
                  Center(
                    child: CyclePlaque(
                      cycleCount: nextCycle,
                      large: true,
                    ),
                  ),
                  const SizedBox(
                    height: _plaqueToCaption,
                  ),
                  Text(
                    tier.label(l10n),
                    textAlign: TextAlign.center,
                    style: textOptionsSectionDescription,
                  ),
                  const SizedBox(
                    height: _sectionSpacing,
                  ),
                  Text(
                    l10n.cycleDialogIntro,
                    style: textOptionsSectionDescription,
                  ),
                  const SizedBox(
                    height: _itemSpacing,
                  ),
                  _ResetItem(
                    iconData: Icons.looks_one,
                    label: l10n.cycleDialogLossLevel,
                  ),
                  const SizedBox(
                    height: _itemSpacing,
                  ),
                  _ResetItem(
                    iconData: Icons.egg,
                    label: l10n.cycleDialogLossForm,
                  ),
                  const SizedBox(
                    height: _itemSpacing,
                  ),
                  _ResetItem(
                    iconData: Icons.lock_outline,
                    label: l10n.cycleDialogLossHardcore(formatNumber(AnchwattSettings.hardcoreUnlockLevel)),
                  ),
                  const SizedBox(
                    height: _sectionSpacing,
                  ),
                  Text(
                    l10n.cycleDialogIrreversible,
                    style: textOptionsSectionDescription,
                  ),
                  Text(
                    l10n.cycleDialogKept,
                    style: textOptionsSectionDescription,
                  ),
                  const SizedBox(
                    height: _sectionSpacing,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    spacing: _actionSpacing,
                    children: [
                      _DialogButton(
                        label: l10n.cycleDialogCancel,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      _DialogButton(
                        label: l10n.cycleDialogConfirm,
                        filled: true,
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetItem extends StatelessWidget {
  static const double _iconSize = 14;
  static const double _iconToLabel = 8;
  // Nudges the glyph onto the first text line when the label wraps.
  static const EdgeInsets _iconPadding = EdgeInsets.only(top: 1);

  final IconData iconData;
  final String label;

  const _ResetItem({
    required this.iconData,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: _iconPadding,
          child: Icon(
            iconData,
            size: _iconSize,
            color: colorMutedDark,
          ),
        ),
        const SizedBox(
          width: _iconToLabel,
        ),
        Expanded(
          child: Text(
            label,
            style: textCycleDialogItem,
          ),
        ),
      ],
    );
  }
}

class _DialogButton extends StatelessWidget {
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 7,
  );

  final String label;
  final VoidCallback onPressed;
  final bool filled;

  const _DialogButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    // The go-ahead is the filled, brand-coloured one and the way out stays
    // hollow: unmistakable at a glance, without painting the reset as a threat.
    final Color foreground = filled ? Colors.white : colorNeutralDark;
    final Color background = filled ? colorPrimary : Colors.transparent;
    final Color borderColor = filled ? colorPrimary : colorNeutralLight;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(
              color: borderColor,
            ),
            borderRadius: borderRadiusOptionsButton,
          ),
          child: Padding(
            padding: _padding,
            child: Text(
              label,
              style: textOptionsCompactButton.copyWith(
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
