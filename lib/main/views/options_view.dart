import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/main/models.dart';
import 'package:anchwatt/main/view_models/anchwatt_view_model.dart';
import 'package:anchwatt/main/view_models/options_view_model.dart';
import 'package:anchwatt/styles/borders.dart';
import 'package:anchwatt/styles/colors.dart';
import 'package:anchwatt/styles/shadows.dart';
import 'package:anchwatt/styles/texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class OptionsView extends StatelessWidget {
  static const double _maxWidth = 400;
  static const EdgeInsets _insetPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 28,
  );
  static const EdgeInsets _bodyPadding = EdgeInsets.fromLTRB(20, 44, 20, 20);
  static const double _spriteSize = 56;
  static const double _sectionSpacing = 24;
  static const double _itemSpacing = 10;

  const OptionsView._();

  static Future<void> show(BuildContext context) {
    final AnchwattViewModel parent = context.read<AnchwattViewModel>();

    return showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider<OptionsViewModel>(
        create: (_) => OptionsViewModel(parent),
        child: const OptionsView._(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            child: const Stack(
              children: [
                SingleChildScrollView(
                  padding: _bodyPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AboutSection(),
                      SizedBox(
                        height: _sectionSpacing,
                      ),
                      _ModeOption(),
                      SizedBox(
                        height: _sectionSpacing,
                      ),
                      _SilentModeOption(),
                      SizedBox(
                        height: _sectionSpacing,
                      ),
                      _GithubOption(),
                      SizedBox(
                        height: _sectionSpacing,
                      ),
                      _UpdateOption(),
                    ],
                  ),
                ),
                Positioned(
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

class _AboutSection extends StatelessWidget {
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 12,
  );
  static const double _spriteToNameSpacing = 6;

  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Selector<OptionsViewModel, String?>(
      selector: (_, vm) => vm.version,
      builder: (_, version, _) => DecoratedBox(
        decoration: const BoxDecoration(
          color: colorOptionsAboutCard,
          borderRadius: borderRadiusOptionsAboutCard,
          boxShadow: shadowOptionsAboutCard,
        ),
        child: Padding(
          padding: _padding,
          child: Column(
            children: [
              Image.asset(
                Evolution.anchwatt.assetPath,
                width: OptionsView._spriteSize,
                height: OptionsView._spriteSize,
                filterQuality: FilterQuality.none,
              ),
              const SizedBox(
                height: _spriteToNameSpacing,
              ),
              Text(
                l10n.anchwatt,
                style: textOptionsAppName,
              ),
              const SizedBox(
                height: 4,
              ),
              if (version != null)
                Text(
                  l10n.optionsAppVersion(version),
                  style: textOptionsAppMeta,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Selector<OptionsViewModel, SoundMode>(
      selector: (_, vm) => vm.soundMode,
      builder: (_, mode, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.optionsModeLabel,
                  style: textOptionsSectionLabel,
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  _descriptionFor(mode, l10n),
                  style: textOptionsSectionDescription,
                ),
              ],
            ),
          ),
          const SizedBox(
            width: OptionsView._itemSpacing,
          ),
          _ModeToggle(
            mode: mode,
          ),
        ],
      ),
    );
  }

  static String _descriptionFor(SoundMode mode, L10n l10n) {
    switch (mode) {
      case SoundMode.corporate:
        return l10n.optionsModeDescriptionCorporate;

      case SoundMode.friday:
        return l10n.optionsModeDescriptionFriday;
    }
  }
}

class _ModeToggle extends StatelessWidget {
  final SoundMode mode;

  const _ModeToggle({
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: SoundMode.values
          .map(
            (m) => _ModeTogglePill(
              mode: m,
              selected: m == mode,
            ),
          )
          .toList(),
    );
  }
}

class _ModeTogglePill extends StatelessWidget {
  static const double _iconSize = 14;
  static const Duration _animationDuration = Duration(milliseconds: 150);
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 5,
  );

  final SoundMode mode;
  final bool selected;

  const _ModeTogglePill({
    required this.mode,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();
    final Color foreground = selected ? Colors.white : colorMutedDark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.read<OptionsViewModel>().setSoundMode(mode),
        child: AnimatedContainer(
          duration: _animationDuration,
          padding: _padding,
          decoration: BoxDecoration(
            color: selected ? mode.accentColor : Colors.transparent,
            border: Border.all(
              color: selected ? mode.accentColor : colorNeutralLight,
            ),
            borderRadius: borderRadiusOptionsModePill,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              Icon(
                mode.iconData,
                color: foreground,
                size: _iconSize,
              ),
              Text(
                mode.label(l10n),
                style: selected ? textOptionsModePillActive : textOptionsModePillInactive,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SilentModeOption extends StatelessWidget {
  const _SilentModeOption();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Selector<OptionsViewModel, bool>(
      selector: (_, vm) => vm.silentModeEnabled,
      builder: (_, enabled, _) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.silentModeLabel,
                  style: textOptionsSectionLabel,
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  l10n.silentModeDescription,
                  style: textOptionsSectionDescription,
                ),
              ],
            ),
          ),
          const SizedBox(
            width: OptionsView._itemSpacing,
          ),
          Transform.scale(
            scale: 0.75,
            child: Switch(
              value: enabled,
              activeThumbColor: Colors.white,
              activeTrackColor: colorWarning,
              inactiveThumbColor: colorMutedDark,
              inactiveTrackColor: colorNeutralLight,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              trackOutlineColor: WidgetStateProperty.resolveWith<Color>(
                (states) => states.contains(WidgetState.selected) ? colorWarning : colorNeutralLight,
              ),
              onChanged: (value) => context.read<OptionsViewModel>().setSilentMode(value),
            ),
          ),
        ],
      ),
    );
  }
}

class _GithubOption extends StatelessWidget {
  const _GithubOption();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            l10n.optionsGithubLabel,
            style: textOptionsSectionLabel,
          ),
        ),
        _OptionButton(
          iconData: Icons.open_in_new,
          label: l10n.optionsGithubButton,
          onPressed: () => context.read<OptionsViewModel>().openGithub(),
        ),
      ],
    );
  }
}

class _UpdateOption extends StatelessWidget {
  const _UpdateOption();

  @override
  Widget build(BuildContext context) {
    final L10n l10n = locator<L10n>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                l10n.optionsUpdatesLabel,
                style: textOptionsSectionLabel,
              ),
            ),
            Selector<OptionsViewModel, OptionsUpdateCheck>(
              selector: (_, vm) => vm.checkState,
              builder: (_, state, _) {
                final bool isLoading = state is OptionsUpdateLoading;

                return _OptionButton(
                  iconData: Icons.refresh,
                  label: l10n.optionsUpdatesCheckButton,
                  loading: isLoading,
                  onPressed: isLoading ? null : () => context.read<OptionsViewModel>().checkForUpdatesNow(),
                );
              },
            ),
          ],
        ),
        Selector<OptionsViewModel, OptionsUpdateCheck>(
          selector: (_, vm) => vm.checkState,
          builder: (_, state, _) {
            final Widget? feedback = switch (state) {
              OptionsUpdateUpToDate() => Padding(
                padding: const EdgeInsets.only(
                  top: 6,
                ),
                child: Text(
                  l10n.optionsUpdatesUpToDate,
                  style: textOptionsSectionDescription.copyWith(
                    color: colorSuccess,
                  ),
                ),
              ),
              OptionsUpdateError() => Padding(
                padding: const EdgeInsets.only(
                  top: 6,
                ),
                child: Text(
                  l10n.optionsUpdatesError,
                  style: textOptionsSectionDescription.copyWith(
                    color: colorError,
                  ),
                ),
              ),
              OptionsUpdateIdle() || OptionsUpdateLoading() => null,
            };

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: feedback ?? const SizedBox.shrink(),
            );
          },
        ),
        Selector<OptionsViewModel, ({String? version, String? url})>(
          selector: (_, vm) => (
            version: vm.availableUpdate?.latestVersion,
            url: vm.availableUpdate?.releaseUrl,
          ),
          builder: (_, data, _) {
            if (data.version == null) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(
                top: OptionsView._itemSpacing,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorNeutralLight,
                  ),
                  borderRadius: borderRadiusOptionsUpdateZone,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.optionsUpdatesAvailable(data.version!),
                          style: textOptionsSectionDescription,
                        ),
                      ),
                      const SizedBox(
                        width: OptionsView._itemSpacing,
                      ),
                      _OptionButton(
                        iconData: Icons.download,
                        label: l10n.optionsUpdatesDownload,
                        filled: true,
                        onPressed: () => context.read<OptionsViewModel>().openLatestRelease(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OptionButton extends StatelessWidget {
  static const double _iconSize = 13;
  static const double _spacing = 6;
  static const Duration _animationDuration = Duration(milliseconds: 150);
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 7,
  );

  final IconData iconData;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool loading;

  const _OptionButton({
    required this.iconData,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;
    final Color foreground = filled ? Colors.white : (enabled ? colorNeutralDark : colorMutedLight);
    final Color background = filled ? (enabled ? colorPrimary : colorMutedLight) : Colors.transparent;
    final Color borderColor = filled ? background : colorNeutralLight;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedContainer(
          duration: _animationDuration,
          padding: _padding,
          decoration: BoxDecoration(
            color: background,
            border: Border.all(
              color: borderColor,
            ),
            borderRadius: borderRadiusOptionsButton,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: _spacing,
            children: [
              if (loading)
                SizedBox(
                  width: _iconSize,
                  height: _iconSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foreground),
                  ),
                )
              else
                Icon(
                  iconData,
                  size: _iconSize,
                  color: foreground,
                ),
              Text(
                label,
                style: textOptionsCompactButton.copyWith(
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
