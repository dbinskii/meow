import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meow/src/core/channels/background_channel.dart';

/// Coordinates background refresh scheduling and native notifications.
class CatBackgroundService {
  CatBackgroundService._internal({
    BackgroundChannel? channel,
    Duration? refreshInterval,
  })  : _channel = channel ?? BackgroundChannel(),
        _refreshInterval = refreshInterval ?? const Duration(minutes: 5);

  /// Shared instance used throughout the application.
  static final CatBackgroundService instance = CatBackgroundService._internal();

  final BackgroundChannel _channel;
  Duration _refreshInterval;
  bool _initialized = false;

  /// Configures the native side and schedules regular refreshes.
  ///
  /// The [refreshInterval] defaults to 5 minutes in order to simplify
  /// development and QA flows; the product requirement of "daily" can be
  /// satisified by providing a longer duration when moving to production.
  Future<void> configure({
    Duration? refreshInterval,
    bool enableNotifications = true,
    bool enableDebugLogging = kDebugMode,
  }) async {
    final resolvedInterval = refreshInterval ?? _refreshInterval;
    if (enableDebugLogging) {
      await _channel.setDebugLogging(true);
    }

    await _channel.initialize(
      refreshIntervalMinutes: resolvedInterval.inMinutes,
      enableNotifications: enableNotifications,
    );
    _refreshInterval = resolvedInterval;
    _initialized = true;
  }

  /// Schedules the repeating native job.
  Future<void> ensureScheduled() async {
    if (!_initialized) {
      await configure();
    }
    await _channel.schedule(_refreshInterval.inMinutes);
  }

  /// Forces an immediate native refresh (primarily used for QA).
  Future<bool> triggerNow() async {
    if (!_initialized) {
      await configure();
    }
    return _channel.triggerNow();
  }

  /// Cancels any scheduled work.
  Future<void> cancel() => _channel.cancel();

  /// Updates the interval for future schedules without re-initialising native.
  Future<void> updateInterval(Duration interval) async {
    _refreshInterval = interval;
    if (_initialized) {
      await _channel.schedule(_refreshInterval.inMinutes);
    }
  }
}
