import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meow/src/core/channels/background_channel.dart';
import 'package:meow/src/features/cat/domain/config/cat_refresh_config.dart';

/// Coordinates background refresh scheduling and native notifications.
class CatBackgroundService {
  CatBackgroundService._internal({
    BackgroundChannel? channel,
    Duration? refreshInterval,
  }) : _channel = channel ?? BackgroundChannel(),
       _refreshInterval = refreshInterval ?? CatRefreshConfig.interval {
    _channel.setMethodCallHandler(_handlePlatformCallback);
  }

  /// Shared instance used throughout the application.
  static final CatBackgroundService instance = CatBackgroundService._internal();

  final BackgroundChannel _channel;
  final _onBackgroundRefreshController = StreamController<DateTime>.broadcast();
  Duration _refreshInterval;
  bool _initialized = false;

  /// Tracks the latest foreground refresh to preserve the background interval.
  DateTime? lastKnownUpdateAt;

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
    final delayMinutes = _resolveDelayMinutes();
    if (delayMinutes != null) {
      await _channel.scheduleWithDelay(delayMinutes);
    } else {
      await _channel.schedule(_refreshInterval.inMinutes);
    }
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

  /// Stream of native background refresh completions.
  Stream<DateTime> get onBackgroundRefresh =>
      _onBackgroundRefreshController.stream;

  /// Handles callbacks from native and updates the most recent refresh time.
  Future<void> _handlePlatformCallback(String method, Object? arguments) async {
    if (method != 'catRefreshed') {
      return;
    }

    DateTime? updatedAt;
    final payload = arguments;
    if (payload is Map) {
      final createdAtRaw = payload['createdAt'];
      if (createdAtRaw is String && createdAtRaw.isNotEmpty) {
        updatedAt = DateTime.tryParse(createdAtRaw);
      }
    }

    final resolved = updatedAt ?? DateTime.now();
    lastKnownUpdateAt = resolved;
    _onBackgroundRefreshController.add(resolved);
  }

  int? _resolveDelayMinutes() {
    final lastKnown = lastKnownUpdateAt;
    if (lastKnown == null) {
      return null;
    }

    final elapsed = DateTime.now().difference(lastKnown);
    final remaining = _refreshInterval - elapsed;
    if (remaining <= Duration.zero) {
      return null;
    }
    final minutes = remaining.inMinutes;
    return minutes > 0 ? minutes : 1;
  }
}
