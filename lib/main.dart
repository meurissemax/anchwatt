import 'package:anchwatt/commons/widgets/text_scale_factor_clamper.dart';
import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/locator.dart';
import 'package:anchwatt/router.dart';
import 'package:anchwatt/settings.dart';
import 'package:anchwatt/styles/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupLocator();

  runApp(App());
}

class App extends StatelessWidget {
  final AppRouter _router = locator<AppRouter>();

  App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      builder: (_, child) => TextScaleFactorClamper(
        child: child!,
      ),
      debugShowCheckedModeBanner: false,
      localeResolutionCallback: (device, supported) {
        if (supported.map((e) => e.languageCode).contains(device?.languageCode)) {
          return device;
        }

        return const Locale(Settings.defaultLanguage, '');
      },
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: _router.config(),
      supportedLocales: L10n.delegate.supportedLocales,
      theme: themeDefault,
      title: Settings.appTitle,
    );
  }
}
