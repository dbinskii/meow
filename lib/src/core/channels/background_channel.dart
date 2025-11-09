import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_channel.dart';

/// Platform channel that bridges background scheduling and notification logic.
class BackgroundChannel extends NativeChannel {
  BackgroundChannel() : super('com.example.meow/background');

  /// Requests any initialization work on the native side.
  Future<void> initialize({
    required int refreshIntervalMinutes,
    bool enableNotifications = true,
  }) {
    return invokeMethod('initialize', {
      'refreshIntervalMinutes': refreshIntervalMinutes,
      'enableNotifications': enableNotifications,
    });
  }

  /// Requests native to schedule the periodic fetch task.
  Future<void> schedule(int refreshIntervalMinutes) {
    return invokeMethod('schedule', {
      'refreshIntervalMinutes': refreshIntervalMinutes,
    });
  }

  /// Cancels all scheduled background work.
  Future<void> cancel() {
    return invokeMethod('cancel');
  }

  /// Requests a discrete immediate refresh.
  Future<bool> triggerNow() async {
    final result = await invokeMethod<bool>('triggerNow');
    return result ?? false;
  }

  /// Enables verbose logging for native diagnostics.
  Future<void> setDebugLogging(bool enabled) {
    return invokeMethod('setDebugLogging', {'enabled': enabled});
  }

  /// Utility to guard native calls during hot-reload cycles.
  @visibleForTesting
  MethodChannel get channelForTesting => channel;
}
