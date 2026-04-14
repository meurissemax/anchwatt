import 'package:anchwatt/l10n/outputs/l10n.dart';
import 'package:anchwatt/router.dart';
import 'package:get_it/get_it.dart';

GetIt locator = GetIt.I;

void setupLocator() {
  locator.allowReassignment = true;

  locator.registerSingleton<L10n>(L10n());
  locator.registerLazySingleton<AppRouter>(AppRouter.new);
}
