import 'package:flutter/material.dart';
import 'package:meow/src/features/cat/domain/entity/cat_entity.dart';
import 'package:meow/src/features/cat/presentation/views/cat_history_view.dart';
import 'package:meow/src/features/cat/presentation/views/cat_history_view_details.dart';
import 'package:meow/src/features/cat/presentation/views/cat_view.dart';
import 'package:meow/src/features/splash/presentation/views/splash_view.dart';

class AppRouter {
  const AppRouter._();

  static const String splash = '/';
  static const String cat = '/cat';
  static const String catHistory = '/cat/history';
  static const String catHistoryDetails = '/cat/history/details';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashView(), settings);
      case cat:
        return _fadeRoute(const CatView(), settings);
      case catHistory:
        return _fadeRoute(const CatHistoryView(), settings);
      case catHistoryDetails:
        final args = settings.arguments;
        if (args is CatHistoryDetailsArgs) {
          return _fadeRoute(CatHistoryViewDetails(cat: args.cat), settings);
        }
        return null;
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

class CatHistoryDetailsArgs {
  const CatHistoryDetailsArgs({required this.cat});

  final CatEntity cat;
}
