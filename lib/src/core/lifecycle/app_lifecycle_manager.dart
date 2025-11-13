import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:meow/src/features/cat/service/cat_background_service.dart';

/// Coordinates background scheduling based on the current app lifecycle.
class AppLifecycleManager with WidgetsBindingObserver {
  AppLifecycleManager({required this.backgroundService});

  final CatBackgroundService backgroundService;

  bool _isInBackground = false;
  bool _isAttached = false;

  /// Starts observing lifecycle changes.
  void attach() {
    if (_isAttached) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _isAttached = true;

    // The app launches in foreground, so make sure no background work is pending.
    unawaited(backgroundService.cancel());
  }

  /// Stops observing lifecycle changes.
  void detach() {
    if (!_isAttached) {
      return;
    }
    WidgetsBinding.instance.removeObserver(this);
    _isAttached = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_isInBackground) {
          _isInBackground = false;
          // Cancel BG task when app is in foreground (like Android)
          // Flutter Timer in CatBloc will handle foreground updates
          unawaited(backgroundService.cancel());
        }
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _scheduleIfNeeded();
        break;
      case AppLifecycleState.hidden:
        _scheduleIfNeeded();
        break;
      case AppLifecycleState.detached:
        _scheduleIfNeeded(force: true);
        break;
    }
  }

  void _scheduleIfNeeded({bool force = false}) {
    if (!_isAttached) {
      return;
    }
    if (!force && _isInBackground) {
      return;
    }
    _isInBackground = true;
    unawaited(backgroundService.ensureScheduled());
  }
}
