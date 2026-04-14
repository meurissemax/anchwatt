import 'package:flutter/widgets.dart';

class TextScaleFactorClamper extends StatelessWidget {
  final double maxScaleFactor;
  final double minScaleFactor;
  final Widget child;

  const TextScaleFactorClamper({
    super.key,
    this.maxScaleFactor = 1.2,
    this.minScaleFactor = 0.8,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(
        textScaler: mediaQuery.textScaler.clamp(
          maxScaleFactor: maxScaleFactor,
          minScaleFactor: minScaleFactor,
        ),
      ),
      child: child,
    );
  }
}
