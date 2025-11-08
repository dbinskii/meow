import 'package:flutter/material.dart';
import 'package:meow/src/features/cat/presentation/views/cat_view.dart';
import 'package:meow/src/features/splash/presentation/views/splash_view.dart';

class AppRouter {
  const AppRouter._();

  static const String splash = '/';
  static const String cat = '/cat';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashView(), settings);
      case cat:
        return _fadeRoute(const CatView(), settings);
      default:
        return null;
    }
  }

  static Route<T> _fadeRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (_, animation, __) =>
          FadeTransition(opacity: animation, child: page),
    );
  }
}
