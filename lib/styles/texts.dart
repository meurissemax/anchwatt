import 'package:anchwatt/styles/colors.dart';
import 'package:flutter/material.dart';

const String fontFamily = 'Inter';

// Base
const TextStyle textBodyMedium = TextStyle(
  color: colorText,
  fontFamily: fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w400,
);

// Anchwatt
const TextStyle textDebugButton = TextStyle(
  fontFamily: fontFamily,
  fontFeatures: [FontFeature.tabularFigures()],
  fontSize: 11,
  fontWeight: FontWeight.w600,
  letterSpacing: 0.5,
);

const TextStyle textLevel = TextStyle(
  fontFamily: fontFamily,
  fontFeatures: [FontFeature.tabularFigures()],
  fontSize: 56,
  fontWeight: FontWeight.w700,
  height: 1,
  letterSpacing: -2,
);

const TextStyle textOptionsAppMeta = TextStyle(
  color: colorMutedDark,
  fontFamily: fontFamily,
  fontFeatures: [FontFeature.tabularFigures()],
  fontSize: 11,
  fontWeight: FontWeight.w400,
);

const TextStyle textOptionsAppName = TextStyle(
  color: colorText,
  fontFamily: fontFamily,
  fontSize: 15,
  fontWeight: FontWeight.w700,
);

const TextStyle textOptionsCompactButton = TextStyle(
  fontFamily: fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w600,
);

const TextStyle textOptionsModePillActive = TextStyle(
  color: Colors.white,
  fontFamily: fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w600,
);

const TextStyle textOptionsModePillInactive = TextStyle(
  color: colorMutedDark,
  fontFamily: fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w600,
);

const TextStyle textOptionsSectionDescription = TextStyle(
  color: colorMutedDark,
  fontFamily: fontFamily,
  fontSize: 11,
  fontWeight: FontWeight.w400,
  height: 1.4,
);

const TextStyle textOptionsSectionLabel = TextStyle(
  color: colorNeutralDark,
  fontFamily: fontFamily,
  fontSize: 12,
  fontWeight: FontWeight.w600,
);

const TextStyle textStageLabel = TextStyle(
  color: colorMutedDark,
  fontFamily: fontFamily,
  fontSize: 14,
  fontWeight: FontWeight.w500,
);


const TextStyle textSystemVolumeLabel = TextStyle(
  color: colorSystemVolumeForeground,
  fontFamily: fontFamily,
  fontFeatures: [FontFeature.tabularFigures()],
  fontSize: 11,
  fontWeight: FontWeight.w500,
);

const TextStyle textXpCounter = TextStyle(
  color: colorMutedLight,
  fontFamily: fontFamily,
  fontFeatures: [FontFeature.tabularFigures()],
  fontSize: 11,
  fontWeight: FontWeight.w400,
);

const TextStyle textXpGainFloater = TextStyle(
  fontFamily: fontFamily,
  fontFeatures: [FontFeature.tabularFigures()],
  fontSize: 14,
  fontWeight: FontWeight.w700,
);
