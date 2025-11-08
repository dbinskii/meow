import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  const AppTypography._();

  static TextTheme textTheme = TextTheme(
    headlineLarge: baseHeadline,
    bodyMedium: baseBody,
  );

  static const TextStyle baseHeadline = TextStyle(
    fontFamily: 'AntonSC',
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.15,
    color: AppColors.textPrimary,
  );

  static const TextStyle baseBody = TextStyle(
    fontFamily: 'Satoshi',
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );
}
