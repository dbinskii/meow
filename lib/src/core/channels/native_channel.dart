import 'package:flutter/services.dart';

/// Base wrapper around a [MethodChannel] used for native communication.
///
/// Each concrete implementation should expose strongly typed methods that
/// internally defer to [invokeMethod].
abstract class NativeChannel {
  NativeChannel(String name) : channel = MethodChannel(name);

  /// Underlying platform channel.
  final MethodChannel channel;

  /// Utility helper for invoking a method and casting the result.
  ///
  /// The [arguments] should only contain JSON-serialisable primitives.
  Future<T?> invokeMethod<T>(String method, [Object? arguments]) {
    return channel.invokeMethod<T>(method, arguments);
  }
}
