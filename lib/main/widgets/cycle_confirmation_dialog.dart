import 'package:anchwatt/commons/utils/number_format.dart';
import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/styles/borders.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:anchwatt/styles/texts.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

// Confirmation gate of the cycle reset. A plain widget rather than a view: it
// holds no state of its own and only answers a yes/no question, leaving the
// reset itself to the caller. Spells out every loss so nobody trips into a
// reset they did not mean.
class CycleConfirmationDialog extends StatelessWidget {
  /* Static variables */

  static const double _maxWidth = 400;
  static const EdgeInsets _insetPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 28,
  );
  static const EdgeInsets _bodyPadding = EdgeInsets.all(20);
  static const double _titleSpacing = 12;
  static const double _itemSpacing = 6;
  static const double _sectionSpacing = 16;
  static const double _actionSpacing = 8;

  /* Constructor */

  const CycleConfirmationDialog._();

  /* Methods */

  // Resolves to true only on an explicit confirmation; cancelling, Escape and
  // a tap outside the dialog all resolve to false.
  static Future<bool> show(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const CycleConfirmationDialog._(),
    );

    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

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
                    l10n.cycleDialogTitle,
                    style: textOptionsAppName,
                  ),
                  const SizedBox(
                    height: _titleSpacing,
                  ),
                  Text(
                    l10n.cycleDialogIntro,
                    style: textOptionsSectionDescription,
                  ),
                  const SizedBox(
                    height: _itemSpacing,
                  ),
                  _LossItem(
                    label: l10n.cycleDialogLossLevel,
                  ),
                  const SizedBox(
                    height: _itemSpacing,
                  ),
                  _LossItem(
                    label: l10n.cycleDialogLossForm,
                  ),
                  const SizedBox(
                    height: _itemSpacing,
                  ),
                  _LossItem(
                    label: l10n.cycleDialogLossHardcore(formatNumber(AnchwattSettings.hardcoreUnlockLevel)),
                  ),
                  const SizedBox(
                    height: _sectionSpacing,
                  ),
                  Text(
                    l10n.cycleDialogIrreversible,
                    style: textOptionsSectionDescription.copyWith(
                      color: colorError,
                    ),
                  ),
                  const SizedBox(
                    height: 4,
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
                        destructive: true,
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

class _LossItem extends StatelessWidget {
  static const double _iconSize = 14;
  static const double _iconToLabel = 6;

  final String label;

  const _LossItem({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.remove,
          size: _iconSize,
          color: colorError,
        ),
        const SizedBox(
          width: _iconToLabel,
        ),
        Expanded(
          child: Text(
            label,
            style: textOptionsSectionLabel,
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
  final bool destructive;

  const _DialogButton({
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    // The destructive action is filled in the error colour while the safe one
    // stays hollow, so the two can never be mistaken for each other.
    final Color foreground = destructive ? Colors.white : colorNeutralDark;
    final Color background = destructive ? colorError : Colors.transparent;
    final Color borderColor = destructive ? colorError : colorNeutralLight;

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
