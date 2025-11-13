import 'dart:io';
import 'package:flutter/cupertino.dart';
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
    // Use CupertinoPageRoute for iOS to support swipe back gesture
    if (Platform.isIOS) {
      return _FadeCupertinoPageRoute<T>(
        settings: settings,
        builder: (_) => page,
      );
    }
    // Use MaterialPageRoute for Android
    return _FadeMaterialPageRoute<T>(settings: settings, builder: (_) => page);
  }
}

class _FadeCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  _FadeCupertinoPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class _FadeMaterialPageRoute<T> extends MaterialPageRoute<T> {
  _FadeMaterialPageRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class CatHistoryDetailsArgs {
  const CatHistoryDetailsArgs({required this.cat});

  final CatEntity cat;
}
