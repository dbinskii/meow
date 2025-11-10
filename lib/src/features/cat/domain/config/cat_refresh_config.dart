import 'package:flutter/foundation.dart';

/// Shared refresh cadence used for both foreground and background updates.
///
/// By keeping this value centralised we guarantee that the caching layer,
/// background scheduler, and foreground refresh logic stay in sync.
@immutable
class CatRefreshConfig {
  const CatRefreshConfig._();

  /// Default automatic refresh interval.
  static const Duration interval = Duration(minutes: 5);
}
