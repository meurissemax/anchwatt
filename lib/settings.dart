enum Environment { dev, prod }

class Settings {
  static const Environment environment = Environment.dev;
  static const String defaultLanguage = 'fr';

  static bool get isDev => environment == Environment.dev;
}
