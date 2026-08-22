import 'package:anchwatt/styles/colors.dart';
import 'package:anchwatt/styles/texts.dart';
import 'package:material_ui/material_ui.dart';

final ThemeData themeDefault = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary: colorPrimary,
    onPrimary: Colors.white,
    secondary: colorSecondary,
    onSecondary: Colors.black,
    error: colorError,
    onError: Colors.white,
    surface: colorSurface,
    onSurface: Colors.black,
  ),
  fontFamily: fontFamily,
  scaffoldBackgroundColor: colorScaffoldBackground,
  textTheme: const TextTheme(
    bodyMedium: textBodyMedium,
  ),
);
