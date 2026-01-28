import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'foreground_service_isolate_platform_interface.dart';

/// An implementation of [ForegroundServiceIsolatePlatform] that uses method channels.
class MethodChannelForegroundServiceIsolate extends ForegroundServiceIsolatePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('foreground_service_isolate');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
