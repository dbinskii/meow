import 'package:flutter/material.dart';
import '../core/navigation/app_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meow',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Satoshi',
        textTheme: AppTypography.textTheme,
      ),
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
