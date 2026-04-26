enum Environment { dev, prod }

class Settings {
  static const Environment environment = Environment.dev;
  static const String defaultLanguage = 'fr';
  static const String githubReleasesLatestEndpoint =
      'https://api.github.com/repos/meurissemax/anchwatt/releases/latest';

  static bool get isDev => environment == Environment.dev;
}
