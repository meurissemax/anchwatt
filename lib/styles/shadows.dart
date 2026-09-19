import 'package:material_ui/material_ui.dart';

// Widgets
// Soft halo under the cycle plaque, tinted with the tier's own colour so the
// emblem seems to float and faintly glow on the white window.
List<BoxShadow> shadowCyclePlaque(Color glow) => <BoxShadow>[
  BoxShadow(
    color: glow,
    blurRadius: 12,
    offset: const Offset(0, 3),
  ),
];

const List<BoxShadow> shadowOptionsAboutCard = <BoxShadow>[
  BoxShadow(
    color: Color(0x1f000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  ),
];
